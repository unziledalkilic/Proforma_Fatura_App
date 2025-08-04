import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../constants/app_constants.dart';
import '../models/invoice.dart';
import '../services/pdf_service.dart';
import '../providers/auth_provider.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isGenerating = false;
  String? _pdfPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final pdfService = PdfService();
      
      // Kullanıcı bilgilerini al
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      final filePath = await pdfService.generateInvoicePdf(
        widget.invoice,
        companyInfo: currentUser,
      );
      
      setState(() {
        _pdfPath = filePath;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfPath == null) return;

    try {
      // Dosyayı Downloads klasörüne kopyala
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Downloads klasörü bulunamadı');
      }

      final fileName = 'Proforma_Fatura_${widget.invoice.invoiceNumber}.pdf';
      final targetPath = '${downloadsDir.path}/$fileName';
      
      final sourceFile = File(_pdfPath!);
      final targetFile = await sourceFile.copy(targetPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF başarıyla indirildi: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Aç',
              onPressed: () => _openFile(targetFile.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya açılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfPath == null) return;

    try {
      // TODO: Share paketi ile paylaşım özelliği eklenebilir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşım özelliği yakında eklenecek'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Önizleme - ${widget.invoice.invoiceNumber}'),
        actions: [
          if (_pdfPath != null) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
              tooltip: 'PDF İndir',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: 'Paylaş',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openFile(_pdfPath!),
              tooltip: 'Dosyayı Aç',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'PDF oluşturuluyor...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'PDF oluşturulurken hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generatePdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_pdfPath == null) {
      return const Center(
        child: Text('PDF yüklenemedi'),
      );
    }

    return Column(
      children: [
        // PDF Önizleme Alanı
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildPdfPreview(),
            ),
          ),
        ),
        
        // Alt Butonlar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.download),
                  label: const Text('PDF İndir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openFile(_pdfPath!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Dosyayı Aç'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPreview() {
    // PDF önizleme için basit bir placeholder
    // Gerçek uygulamada flutter_pdfview paketi kullanılabilir
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Proforma Fatura',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.invoice.invoiceNumber,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PDF Önizleme',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PDF dosyası başarıyla oluşturuldu.\nİndirmek için aşağıdaki butonu kullanın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 