import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as path from "path";
import * as fs from "fs";

const db = admin.firestore();

export const setupPartsData = onRequest(
  { region: "asia-northeast3", timeoutSeconds: 540, memory: "512MiB" },
  async (req, res): Promise<void> => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    logger.info("Starting parts data migration from JSON files...");

    try {
      const dataDir = path.join(__dirname, '../data');
      const cpuData = JSON.parse(fs.readFileSync(path.join(dataDir, 'all_cpus_combined.json'), 'utf-8'));
      const gpuData = JSON.parse(fs.readFileSync(path.join(dataDir, 'cleaned_gpu_data.json'), 'utf-8'));
      const mainboardData = JSON.parse(fs.readFileSync(path.join(dataDir, 'cleaned_mainboard_data.json'), 'utf-8'));

      let allParts: any[] = [];

      if (Array.isArray(cpuData)) {
        allParts = allParts.concat(cpuData.map((part: any) => ({ ...part, category: "cpu" })));
      }
      if (Array.isArray(gpuData)) {
        allParts = allParts.concat(gpuData.map((part: any) => ({ ...part, category: "gpu" })));
      }
      if (Array.isArray(mainboardData)) {
        allParts = allParts.concat(mainboardData.map((part: any) => ({ ...part, category: "mainboard" })));
      }

      if (allParts.length === 0) {
        res.status(200).send({ success: true, message: "No data to upload." });
        return;
      }

      const partsCollection = db.collection("parts");
      const BATCH_SIZE = 450;
      let totalUploaded = 0;

      for (let i = 0; i < allParts.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const chunk = allParts.slice(i, i + BATCH_SIZE);

        for (const part of chunk) {
          const docId = part.partId || part.part_id || db.collection("parts").doc().id;

          if (docId) {
            const docRef = partsCollection.doc(docId);

            // undefined 값 제거 함수
            const removeUndefined = (obj: any): any => {
              return Object.entries(obj).reduce((acc, [key, value]) => {
                if (value !== undefined && value !== null) {
                  acc[key] = value;
                }
                return acc;
              }, {} as any);
            };

            const dataToSave: { [key: string]: any } = {
              partId: docId,
              category: part.category,
              brand: part.brand,
              modelName: part.model || part.name || part.modelName,
              referencePrice: part.reference_price ?? (part.pricing ? part.pricing.basePrice : null),
              imageUrl: part.image_url || null,
              powerConsumptionW: part.power_consumption_w ?? (part.specs ? part.specs.performance?.recommendedPsuWatt : null),
              generation: part.generation || null,
              codename: part.codename || null,
              packaging: part.packaging || null,
              ...(part.category === "cpu" && removeUndefined({
                socket: part.socket,
                hasIntegratedGraphics: part.has_integrated_graphics,
                cores: part.cores,
                threads: part.threads,
                baseClockGhz: part.base_clock_ghz,
                boostClockGhz: part.boost_clock_ghz,
                l3CacheMb: part.l3_cache_mb,
                igpuName: part.igpu_name,
                igpuFreqMhz: part.igpu_freq_mhz,
                memory: part.memory,
                coolerIncluded: part.cooler_included,
              })),
              ...(part.category === "gpu" && part.specs && removeUndefined({
                chipset: part.specs.chipsetModel,
                memorySizeGb: part.specs.memory?.sizeGb,
                memoryType: part.specs.memory?.type,
                interfaceType: `${part.specs.interface?.type ?? ''} ${part.specs.interface?.version ?? ''} x${part.specs.interface?.lanes ?? ''}`.trim() || null,
                boostClockMhz: part.specs.boostClockMhz,
                cudaCores: part.specs.performance?.cudaCores,
                tdpW: part.specs.tdpW,
              })),
              ...(part.category === "mainboard" && part.specs && removeUndefined({
                socket: part.specs.socket,
                chipset: part.specs.chipset,
                formFactor: part.specs.formFactor,
                memorySlots: part.specs.memory?.slots,
                maxMemoryGb: part.specs.memory?.maxCapacityGb,
                memoryType: part.specs.memory?.type,
                pcieSlots: (part.specs.pciExpress?.x16Slots ?? 0) + (part.specs.pciExpress?.x4Slots ?? 0) + (part.specs.pciExpress?.x1Slots ?? 0),
                sataPorts: part.specs.storage?.sata3Ports,
                m2Slots: part.specs.storage?.m2Slots,
              })),
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            // 최종적으로 undefined 제거
            const cleanData = removeUndefined(dataToSave);
            batch.set(docRef, cleanData);
          }
        }

        await batch.commit();
        totalUploaded += chunk.length;
        logger.info(`Progress: ${totalUploaded}/${allParts.length}`);
      }

      logger.info(`Successfully uploaded ${totalUploaded} parts!`);
      res.status(200).send({ success: true, message: `Successfully uploaded ${totalUploaded} parts.` });

    } catch (error) {
      logger.error("Error:", error);
      res.status(500).send({ success: false, error: (error as Error).message });
    }
  }
);
