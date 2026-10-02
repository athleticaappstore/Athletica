import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    func makeUIViewController(context: Context) -> ScannerController { let c=ScannerController(); c.onCode=onCode; return c }
    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {}
}

final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let session=AVCaptureSession(); var onCode:((String)->Void)?; var preview:AVCaptureVideoPreviewLayer!
    override func viewDidLoad(){super.viewDidLoad();view.backgroundColor=.black;configure()}
    private func configure(){guard let device=AVCaptureDevice.default(for:.video),let input=try? AVCaptureDeviceInput(device:device),session.canAddInput(input) else{return};session.addInput(input);let output=AVCaptureMetadataOutput();guard session.canAddOutput(output) else{return};session.addOutput(output);output.setMetadataObjectsDelegate(self,queue:.main);output.metadataObjectTypes=[.ean8,.ean13,.upce,.code128,.code39,.qr];preview=AVCaptureVideoPreviewLayer(session:session);preview.videoGravity=.resizeAspectFill;preview.frame=view.bounds;view.layer.addSublayer(preview);DispatchQueue.global(qos:.userInitiated).async{self.session.startRunning()}}
    override func viewDidLayoutSubviews(){super.viewDidLayoutSubviews();preview?.frame=view.bounds}
    func metadataOutput(_ output:AVCaptureMetadataOutput,didOutput metadataObjects:[AVMetadataObject],from connection:AVCaptureConnection){guard let obj=metadataObjects.first as? AVMetadataMachineReadableCodeObject,let code=obj.stringValue else{return};session.stopRunning();onCode?(code)}
}
