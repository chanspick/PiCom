import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as path from "path";
import * as fs from "fs";

// Firebase Admin SDK 초기화
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

// ---------- Helpers ----------
const asNum = (v: any): number | null => {
  if (v === null || v === undefined || v === "") return null;
  const n = Number(v);
  return isFinite(n) ? n : null;
};
const asInt = (v: any): number | null => {
  const n = asNum(v);
  return n === null ? null : Math.trunc(n);
};
const asStr = (v: any): string | null => {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return s.length > 0 ? s : null;
};
const asBool = (v: any): boolean | null => {
    if (v === null || v === undefined) return null;
    if (typeof v === 'boolean') return v;
    if (typeof v === 'string') {
        const lowerV = v.toLowerCase();
        if (lowerV === 'true') return true;
        if (lowerV === 'false') return false;
    }
    return null;
};

const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9-]/g, "-").replace(/-+/g, '-').replace(/^-|-$/g, '');

const removeNulls = (obj: Record<string, any>): Record<string, any> => {
  const newObj: Record<string, any> = {};
  for (const key in obj) {
    if (obj[key] !== null && obj[key] !== undefined) {
      if (typeof obj[key] === 'object' && !Array.isArray(obj[key])) {
        const nested = removeNulls(obj[key]);
        if (Object.keys(nested).length > 0) {
          newObj[key] = nested;
        }
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  return newObj;
};

// ---------- ID Generator ----------
const genId = (category: string, brand: string, model: string): string => {
    return slug(`${category}-${brand}-${model}`);
};

// ---------- Normalizers per category ----------
const normalizeCPU = (raw: any) => {
  const brand = asStr(raw.brand) ?? "unknown";
  const model = asStr(raw.model ?? raw.name) ?? "unknown";
  const partId = genId("cpu", brand, model);

  const data = {
    partId,
    category: "cpu",
    brand,
    modelName: model,
    referencePrice: asInt(raw.reference_price),
    imageUrl: asStr(raw.image_url),
    socket: asStr(raw.socket),
    hasIntegratedGraphics: asBool(raw.has_integrated_graphics),
    powerConsumptionW: asInt(raw.power_consumption_w),
    cores: asInt(raw.cores),
    threads: asInt(raw.threads),
    baseClockGhz: asNum(raw.base_clock_ghz),
    boostClockGhz: asNum(raw.boost_clock_ghz),
    l3CacheMb: asInt(raw.l3_cache_mb),
    igpuName: asStr(raw.igpu_name),
    igpuFreqMhz: asInt(raw.igpu_freq_mhz),
    generation: asStr(raw.generation),
    codename: asStr(raw.codename),
    memory: {
      type: asStr(raw.memory?.type),
      maxSpeedMhz: asInt(raw.memory?.max_speed_mhz),
      channels: asInt(raw.memory?.channels),
    },
    coolerIncluded: asBool(raw.cooler_included),
    packaging: asStr(raw.packaging),
    processNm: asInt(raw.process_nm),
    raw,
  };
  return removeNulls(data);
};

const normalizeGPU = (raw: any) => {
  const brand = asStr(raw.brand) ?? "unknown";
  const model = asStr(raw.name) ?? "unknown";
  const partId = genId("gpu", brand, model);

  const data = {
    partId,
    category: "gpu",
    brand,
    modelName: model,
    referencePrice: asInt(raw.price),
    chipset: {
      vendor: asStr(raw.chipset?.vendor),
      model: asStr(raw.chipset?.model),
      series: asStr(raw.chipset?.series),
      cudaCores: asInt(raw.chipset?.cuda_cores),
    },
    memory: {
      sizeGb: asInt(raw.memory?.size_gb),
      type: asStr(raw.memory?.type),
      busWidthBit: asInt(raw.memory?.bus_width_bit),
      speedMhz: asInt(raw.memory?.speed_mhz),
    },
    clockSpeeds: {
      baseMhz: asInt(raw.clock_speeds?.base_mhz),
      boostMhz: asInt(raw.clock_speeds?.boost_mhz),
      ocMhz: asInt(raw.clock_speeds?.oc_mhz),
    },
    interface: {
      type: asStr(raw.interface?.type),
      version: asStr(raw.interface?.version),
      lanes: asInt(raw.interface?.lanes),
    },
    outputs: {
      displayPort: asInt(raw.outputs?.display_port),
      hdmi: asInt(raw.outputs?.hdmi),
      dvi: asInt(raw.outputs?.dvi),
      multiMonitorSupport: asInt(raw.outputs?.multi_monitor_support),
    },
    features: {
      support4k: asBool(raw.features?.support_4k),
      support8k: asBool(raw.features?.support_8k),
      led: asBool(raw.features?.led),
      backplate: asBool(raw.features?.backplate),
      cooling: {
        fanCoolerCount: asInt(raw.features?.cooling?.fan_cooler_count),
        vaporChamber: asBool(raw.features?.cooling?.vapor_chamber),
        liquidCooled: asBool(raw.features?.cooling?.liquid_cooled),
      },
    },
    power: {
      recommendedPsuWatt: asInt(raw.power?.recommended_psu_watt),
    },
    dimensionsMm: {
      length: asInt(raw.dimensions_mm?.length),
      height: asInt(raw.dimensions_mm?.height),
      width: asInt(raw.dimensions_mm?.width),
    },
    raw,
  };
  return removeNulls(data);
};

const normalizeMB = (raw: any) => {
  const brand = asStr(raw.brand) ?? "unknown";
  const model = asStr(raw.name) ?? "unknown";
  const partId = genId("mainboard", brand, model);

  const data = {
    partId,
    category: "mainboard",
    brand,
    modelName: model,
    referencePrice: asInt(raw.price),
    chipset: asStr(raw.chipset),
    socket: asStr(raw.socket),
    formFactor: asStr(raw.form_factor ?? raw.form_factor_simple),
    platform: asStr(raw.platform),
    memory: {
      type: asStr(raw.memory?.type ?? raw.memory_type),
      maxSpeedMhz: asInt(raw.memory?.max_speed_mhz ?? raw.memory_max_speed),
      maxCapacityGb: asInt(raw.memory?.max_capacity_gb ?? raw.memory_max_capacity),
      slots: asInt(raw.memory?.slots ?? raw.memory_slots),
    },
    storage: {
      m2Slots: asInt(raw.storage?.m2_slots ?? raw.m2_slots),
      sata3Ports: asInt(raw.storage?.sata3_ports ?? raw.sata_ports),
    },
    pciExpress: {
      pcie5_0: asBool(raw.pci_express?.pcie_5_0 ?? raw.pcie_5_0),
      pcie4_0: asBool(raw.pci_express?.pcie_4_0 ?? raw.pcie_4_0),
      x16Slots: asInt(raw.pci_express?.x16_slots ?? raw.pcie_x16_slots),
      x4Slots: asInt(raw.pci_express?.x4_slots),
      x1Slots: asInt(raw.pci_express?.x1_slots),
    },
    connectivity: {
        lanPorts: asInt(raw.lan?.ports ?? raw.lan_ports),
        lanSpeedGbps: asNum(raw.lan_speed_gbps),
        lanSpec: asStr(raw.lan?.spec ?? raw.lan_speed),
        wireless: asBool(raw.wireless_lan ?? raw.wireless),
        bluetooth: asBool(raw.bluetooth),
    },
    raw,
  };
  return removeNulls(data);
};

// ---------- Main Function ----------
export const setupPartsData = onRequest(
  { region: "asia-northeast3", timeoutSeconds: 540, memory: "512MiB" },
  async (req, res): Promise<void> => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    logger.info("Starting parts data migration from JSON files...");

    try {
      // __dirname은 현재 파일이 있는 디렉토리를 가리킵니다.
      // functions/lib/index.js 에 있으므로, ../data 로 이동해야 합니다.
      const dataDir = path.join(__dirname, "..", "data");
      const cpuData = JSON.parse(fs.readFileSync(path.join(dataDir, "all_cpus_combined.json"), "utf-8"));
      const gpuData = JSON.parse(fs.readFileSync(path.join(dataDir, "cleaned_gpu_data.json"), "utf-8"));
      const mainboardData = JSON.parse(fs.readFileSync(path.join(dataDir, "cleaned_mainboard_data.json"), "utf-8"));

      const cpuArr: any[] = Array.isArray(cpuData) ? cpuData : [];
      const gpuArr: any[] = Array.isArray(gpuData) ? gpuData : [];
      const mbArr: any[] = Array.isArray(mainboardData) ? mainboardData : [];

      if (cpuArr.length + gpuArr.length + mbArr.length === 0) {
        res.status(200).send({ success: true, message: "No data to upload." });
        return;
      }

      const partsCollection = db.collection("parts");
      const BATCH_SIZE = 400;

      let total = 0;
      let cntCPU = 0;
      let cntGPU = 0;
      let cntMB = 0;

      // Upload helper
      const uploadChunk = async (docs: any[], normalizer: (r: any) => any, cat: "cpu" | "gpu" | "mainboard") => {
        for (let i = 0; i < docs.length; i += BATCH_SIZE) {
          const batch = db.batch();
          const chunk = docs.slice(i, i + BATCH_SIZE);

          for (const raw of chunk) {
            try {
              const data = normalizer(raw);
              const partId = data.partId;

              if (!partId || typeof partId !== 'string' || partId.length === 0) {
                logger.warn(`Skipping document due to invalid partId for category ${cat}:`, raw.name ?? raw.model);
                continue;
              }
              if (partId.includes('unknown')) {
                logger.warn(`Generated partId contains 'unknown' for category ${cat}:`, raw.name ?? raw.model);
              }


              const docRef = partsCollection.doc(partId);
              batch.set(
                docRef,
                {
                  ...data,
                  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                { merge: true }
              );

              total += 1;
              if (cat === "cpu") cntCPU += 1;
              if (cat === "gpu") cntGPU += 1;
              if (cat === "mainboard") cntMB += 1;
            } catch (e: any) {
              logger.error(`[normalize ${cat}] failed:`, e.message, raw?.name ?? raw?.model ?? raw?.brand);
            }
          }

          await batch.commit();
          logger.info(`Committed ${Math.min(i + BATCH_SIZE, docs.length)}/${docs.length} for ${cat}`);
        }
      };

      await uploadChunk(cpuArr, normalizeCPU, "cpu");
      await uploadChunk(gpuArr, normalizeGPU, "gpu");
      await uploadChunk(mbArr, normalizeMB, "mainboard");

      logger.info(`Completed: total=${total}, cpu=${cntCPU}, gpu=${cntGPU}, mainboard=${cntMB}`);
      res.status(200).send({
        success: true,
        message: "Upload finished.",
        counts: { total, cpu: cntCPU, gpu: cntGPU, mainboard: cntMB },
      });
    } catch (error: any) {
      logger.error("Error:", error);
      res.status(500).send({ success: false, error: error.message });
    }
  }
);