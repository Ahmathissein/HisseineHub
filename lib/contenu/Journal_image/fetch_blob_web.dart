import 'dart:html';
import 'dart:typed_data';
import 'dart:async';

Future<Uint8List> fetchBlobAsBytes(String blobUrl) async {
  final request = await HttpRequest.request(
    blobUrl,
    responseType: 'blob',
  );
  final blob = request.response as Blob;

  final reader = FileReader();
  final completer = Completer<Uint8List>();

  reader.readAsArrayBuffer(blob);
  reader.onLoadEnd.listen((_) {
    // ✅ CORRECTION ICI
    if (reader.result is ByteBuffer) {
      final buffer = reader.result as ByteBuffer;
      completer.complete(Uint8List.view(buffer));
    } else if (reader.result is Uint8List) {
      completer.complete(reader.result as Uint8List);
    } else {
      completer.completeError(
          Exception("Erreur: result n’est pas un ByteBuffer ni Uint8List (type: ${reader.result.runtimeType})"));
    }
  });

  return completer.future;
}
