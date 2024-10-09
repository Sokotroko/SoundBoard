import UIKit
import AVFoundation

class SoundViewController: UIViewController {

    @IBOutlet weak var grabarButton: UIButton!
    @IBOutlet weak var reproducirButton: UIButton!
    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var agregarButton: UIButton!
    @IBOutlet weak var tiempoGrabacionLabel: UILabel!
    @IBOutlet weak var volumenSlider: UISlider!
    var grabarAudio: AVAudioRecorder?
    var reproducirAudio: AVAudioPlayer?
    var audioURL: URL?
    var timer: Timer?
    var tiempoTranscurrido: TimeInterval = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        configurarGrabacion()
        reproducirButton.isEnabled = false
        agregarButton.isEnabled = false
        volumenSlider.value = 1.0
    }
    
    @IBAction func volumenChanged(_ sender: UISlider) {
        let volumen = sender.value
        reproducirAudio?.volume = volumen
    }
    
    func configurarGrabacion() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
            
            let basePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let pathComponents = [basePath, "audio.m4a"]
            audioURL = NSURL.fileURL(withPathComponents: pathComponents)!
            
            print("*********************")
            print(audioURL!)
            print("*********************")
            
            var settings: [String: AnyObject] = [:]
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC) as AnyObject
            settings[AVSampleRateKey] = 44100.0 as AnyObject
            settings[AVNumberOfChannelsKey] = 2 as AnyObject
            
            grabarAudio = try AVAudioRecorder(url: audioURL!, settings: settings)
            grabarAudio!.prepareToRecord()
        } catch let error {
            print("Error configurando la grabación: \(error.localizedDescription)")
        }
    }
    
    @objc func actualizarTiempoGrabacion() {
        tiempoTranscurrido += 1 // Incrementa el tiempo en 1 segundo
        let minutos = Int(tiempoTranscurrido) / 60
        let segundos = Int(tiempoTranscurrido) % 60
        tiempoGrabacionLabel.text = String(format: "%02d:%02d", minutos, segundos) // Formato MM:SS
    }
    
    @IBAction func grabarTapped(_ sender: Any) {
        if grabarAudio!.isRecording {
            // Detener la grabación
            grabarAudio?.stop()
            grabarButton.setTitle("GRABAR", for: .normal)
            reproducirButton.isEnabled = true
            agregarButton.isEnabled = true
            
            // Detener el temporizador
            timer?.invalidate()
        } else {
            // Empezar a grabar
            grabarAudio?.record()
            grabarButton.setTitle("DETENER", for: .normal)
            reproducirButton.isEnabled = false
            
            // Reiniciar el temporizador
            tiempoTranscurrido = 0
            tiempoGrabacionLabel.text = "00:00"
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(actualizarTiempoGrabacion), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func reproducirTapped(_ sender: Any) {
        do {
            try reproducirAudio = AVAudioPlayer(contentsOf: audioURL!)
            reproducirAudio!.play()
            print("Reproduciendo . . .")
        } catch {
            print("Error reproduciendo el audio: \(error.localizedDescription)")
        }
    }
    
    @IBAction func agregarTapped(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let grabacion = Grabacion(context: context)
        
        // Asignar nombre y audio
        grabacion.nombre = nombreTextField.text
        grabacion.audio = NSData(contentsOf: audioURL!)! as Data
        
        // Usar el tiempo actual de grabación
        let duracionGrabada = tiempoTranscurrido
        print("Duración guardada:", duracionGrabada)
        
        // Asignar la duración de la grabación
        grabacion.duracion = duracionGrabada
        
        // Guardar el contexto de Core Data
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        // Volver a la pantalla anterior
        navigationController!.popViewController(animated: true)
    }
}
