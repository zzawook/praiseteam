import 'package:file_picker_web/file_picker_web.dart';

// Safari can focus the page before Files/iCloud delivers the selected file.
// The plugin's focus fallback treats that as cancellation after only 500 ms.
// Use the input's actual change/cancel events instead.
const sheetPickerWebOptions = FilePickerWebOptions(cancelUploadOnWindowBlur: false);
