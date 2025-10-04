import 'package:flutter/material.dart';
import '../models/pc_component.dart';

class PcAssemblyScreen extends StatefulWidget {
  const PcAssemblyScreen({super.key});

  @override
  State<PcAssemblyScreen> createState() => _PcAssemblyScreenState();
}

class _PcAssemblyScreenState extends State<PcAssemblyScreen> {
  final Map<String, PcComponent?> _selectedComponents = {
    'CPU': null,
    'Motherboard': null,
    'RAM': null,
    'Storage': null,
    'Graphics Card': null,
    'Power Supply': null,
    'Case': null,
    'Cooler': null,
    'Software': null,
  };

  bool _assemblyRequested = false;

  final Map<String, List<PcComponent>> _componentOptions = {
    'CPU': [
      PcComponent(name: 'Intel Core i9-13900K', category: 'CPU', price: 850000),
      PcComponent(name: 'AMD Ryzen 9 7950X', category: 'CPU', price: 800000),
    ],
    'Motherboard': [
      PcComponent(name: 'ASUS ROG Maximus Z790 Hero', category: 'Motherboard', price: 700000),
      PcComponent(name: 'Gigabyte X670 AORUS Elite AX', category: 'Motherboard', price: 450000),
    ],
    'RAM': [
      PcComponent(name: 'G.Skill Trident Z5 RGB 32GB', category: 'RAM', price: 250000),
      PcComponent(name: 'Corsair Vengeance DDR5 32GB', category: 'RAM', price: 230000),
    ],
    'Storage': [
      PcComponent(name: 'Samsung 980 Pro 2TB', category: 'Storage', price: 300000),
      PcComponent(name: 'WD Black SN850X 2TB', category: 'Storage', price: 280000),
    ],
    'Graphics Card': [
      PcComponent(name: 'NVIDIA GeForce RTX 4090', category: 'Graphics Card', price: 2500000),
      PcComponent(name: 'AMD Radeon RX 7900 XTX', category: 'Graphics Card', price: 1800000),
    ],
    'Power Supply': [
      PcComponent(name: 'Corsair AX1600i', category: 'Power Supply', price: 600000),
      PcComponent(name: 'SeaSonic PRIME TX-1000', category: 'Power Supply', price: 400000),
    ],
    'Case': [
      PcComponent(name: 'Lian Li PC-O11 Dynamic EVO', category: 'Case', price: 250000),
      PcComponent(name: 'Fractal Design Meshify 2', category: 'Case', price: 200000),
    ],
    'Cooler': [
      PcComponent(name: 'Noctua NH-D15', category: 'Cooler', price: 150000),
      PcComponent(name: 'Corsair iCUE H150i ELITE CAPELLIX XT', category: 'Cooler', price: 300000),
    ],
    'Software': [
      PcComponent(name: 'Windows 11 Home', category: 'Software', price: 150000),
      PcComponent(name: 'Microsoft Office 2023', category: 'Software', price: 200000),
    ],
  };

  void _selectComponent(String category, PcComponent component) {
    setState(() {
      _selectedComponents[category] = component;
    });
  }

  double get _totalPrice {
    double total = 0;
    _selectedComponents.forEach((key, value) {
      if (value != null) {
        total += value.price;
      }
    });
    if (_assemblyRequested) {
      total += 50000;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC 조립'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _selectedComponents.keys.map((category) {
                final selectedComponent = _selectedComponents[category];
                return ListTile(
                  title: Text(category),
                  subtitle: Text(selectedComponent?.name ?? '선택되지 않음'),
                  trailing: ElevatedButton(
                    child: const Text('선택'),
                    onPressed: () => _showComponentSelectionDialog(category),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('조립 서비스'),
                  subtitle: const Text('전문가가 안전하게 조립해드립니다.'),
                  value: _assemblyRequested,
                  onChanged: (bool? value) {
                    setState(() {
                      _assemblyRequested = value!;
                    });
                  },
                  secondary: const Text('₩50000'),
                ),
                const Divider(),
                const Text(
                  '선택된 부품',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ..._selectedComponents.entries
                    .where((entry) => entry.value != null)
                    .map((entry) => ListTile(
                          title: Text(entry.key),
                          trailing: Text(entry.value!.name),
                        )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '총액',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₩${_totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('장바구니에 담기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComponentSelectionDialog(String category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$category 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _componentOptions[category]!.length,
              itemBuilder: (context, index) {
                final component = _componentOptions[category]![index];
                return ListTile(
                  title: Text(component.name),
                  subtitle: Text('₩${component.price.toStringAsFixed(0)}'),
                  onTap: () {
                    _selectComponent(category, component);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
