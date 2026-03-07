import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../routes/app_pages.dart';

enum DocumentFilter { all, urgent, verified, more }

enum DocumentFileType { pdf, xlsx, image }

class LegalDocumentItem {
  final String name;
  final String size;
  final bool synced;
  final DocumentFileType fileType;

  const LegalDocumentItem({
    required this.name,
    required this.size,
    this.synced = true,
    required this.fileType,
  });
}

class LegalDocumentsController extends BaseController {
  final selectedFilter = DocumentFilter.all.obs;

  final documents = <LegalDocumentItem>[
    const LegalDocumentItem(
      name: 'Property_Deed.pdf',
      size: '2.4 MB',
      fileType: DocumentFileType.pdf,
    ),
    const LegalDocumentItem(
      name: 'Insurance_Policy_2024.pdf',
      size: '1.1 MB',
      fileType: DocumentFileType.pdf,
    ),
    const LegalDocumentItem(
      name: 'Renovation_Receipts.xlsx',
      size: '450 KB',
      fileType: DocumentFileType.xlsx,
    ),
    const LegalDocumentItem(
      name: 'ID_Proof_Front.jpg',
      size: '890 KB',
      fileType: DocumentFileType.image,
    ),
  ];

  void goBack() => Get.back();

  void openSearch() {
    // TODO: open search
  }

  void selectFilter(DocumentFilter filter) {
    selectedFilter.value = filter;
  }

  void openDocumentOptions(LegalDocumentItem item) {
    // TODO: show bottom sheet or menu (view, download, delete, etc.)
  }

  void uploadDocument() {
    Get.toNamed(Routes.DOCUMENT_SCANNER);
  }
}
