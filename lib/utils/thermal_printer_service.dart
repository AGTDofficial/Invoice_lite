import 'package:blue_thermal_printer/blue_thermal_printer.dart' show BlueThermalPrinter;
import 'package:intl/intl.dart';

class ThermalPrinterService {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  Future<void> printInvoice({
    required String invoiceNumber,
    required String partyName,
    required DateTime date,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    double? discount,
    double? roundOff,
    String? footer,
  }) async {
    try {
      bool isConnected = await printer.isConnected ?? false;
      if (!isConnected) {
        final devices = await printer.getBondedDevices();
        if (devices.isNotEmpty) {
          await printer.connect(devices.first);
        } else {
          throw 'No paired thermal printers found.';
        }
      }

      printer.printCustom('MY COMPANY', 3, 1);
      printer.printCustom('GSTIN: 22XXXXXXXZ5', 1, 1);
      printer.printCustom('Phone: 9876543210', 1, 1);
      printer.printNewLine();
      printer.printCustom('INVOICE', 2, 1);
      printer.printCustom('Invoice No: $invoiceNumber', 1, 0);
      printer.printCustom('Date: ${DateFormat('dd-MM-yyyy').format(date)}', 1, 0);
      printer.printCustom('To: $partyName', 1, 0);
      printer.printCustom('-----------------------------', 1, 1);

      for (var item in items) {
        printer.printCustom('${item['itemName']}', 1, 0);
        printer.printCustom(
          'Qty: ${item['quantity']}  Rate: ${item['price']}',
          1,
          0,
        );
        printer.printCustom('Amount: ₹${(item['quantity'] * item['price']).toStringAsFixed(2)}', 1, 0);
        printer.printNewLine();
      }

      printer.printCustom('-----------------------------', 1, 1);
      if (discount != null) {
        printer.printCustom('Discount: ₹${discount.toStringAsFixed(2)}', 1, 2);
      }
      if (roundOff != null) {
        printer.printCustom('Round Off: ₹${roundOff.toStringAsFixed(2)}', 1, 2);
      }
      printer.printCustom('Total: ₹${totalAmount.toStringAsFixed(2)}', 2, 2);
      printer.printCustom('-----------------------------', 1, 1);
      if (footer != null) {
        printer.printCustom(footer, 1, 1);
      }
      printer.printNewLine();
      printer.printNewLine();
      printer.paperCut();
    } catch (e) {
      rethrow;
    }
  }
} 