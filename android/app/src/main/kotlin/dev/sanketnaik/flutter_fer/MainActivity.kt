package dev.sanketnaik.flutter_fer

import android.content.Context
import android.graphics.Bitmap
import android.os.Bundle
import android.os.PersistableBundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.opencv.android.BaseLoaderCallback
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgcodecs.Imgcodecs.imread
import org.opencv.imgcodecs.Imgcodecs.imwrite
import org.opencv.imgproc.Imgproc.*
import org.opencv.objdetect.CascadeClassifier
import org.pytorch.IValue
import org.pytorch.Module
import org.pytorch.PyTorchAndroid
import org.pytorch.Tensor
import org.pytorch.torchvision.TensorImageUtils
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream


class MainActivity: FlutterActivity() {
    private val CHANNEL = "dev.sanketnaik.flutter_fer/fer"
    private var faceDetector: CascadeClassifier? = null;
    var module: Module? = null

    override fun onStart() {
        super.onStart()

        Log.i("FACE_DETECTION", "LOADING CASCADE CLASSIFIER")
        val inputStream: InputStream = resources.openRawResource(R.raw.haarcascade_frontalface_default)
        val cascadeDir = getDir("cascade", Context.MODE_PRIVATE)
        val mCascadeFile = File(cascadeDir, "haarcascade_frontalface_default.xml")
        val os: FileOutputStream = FileOutputStream(mCascadeFile)

        val buffer = ByteArray(4096)
        var byteRead = inputStream.read(buffer)
        while (byteRead != -1) {
            os.write(buffer, 0, byteRead)
            byteRead = inputStream.read(buffer)
        }

        inputStream.close()
        os.close()

        faceDetector = CascadeClassifier(mCascadeFile.absolutePath)


        try {
            module =  PyTorchAndroid.loadModuleFromAsset(assets, "convnet-traced-new.pt")
            Log.i("PYTORCH", "MODULE LOADED SUCCESSFULLY")
        }catch (e: IOException){
            Log.i("IO_EXCEPTION", "IO EXCEPTION WHILE LOADING THE MODEL")
        }
    }

    init {
        Log.i("OPENCV", "LOADING_OPENCV")
        if(OpenCVLoader.initDebug()){
            Log.i("OPEN_CV", "LOADED OPENCV");
        }else{
            Log.e("OPEN_CV", "FAILED TO LOAD OPENCV")
        }
    }


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if(call.method == "predict"){
                val args = call.arguments as Map<String, Any>
                val imagePath = predict(args["imagePath"] as String)
                if(imagePath != null){
                    result.success(imagePath)
                }else{
                    result.error("ERROR", "Something went wrong", null);
                }
            } else{
                result.error("ERROR", "Something went wrong", null)
            }
        }
    }

    private fun predict(imagePath: String): MutableList<String> {
        val startTime = System.nanoTime()
//        Log.i("OPENCV", "LOADING_OPENCV")
//        if(OpenCVLoader.initDebug()){
//            Log.i("OPEN_CV", "LOADED OPENCV");
//        }else{
//            Log.e("OPEN_CV", "FAILED TO LOAD OPENCV")
//        }

        val originalImage: Mat = imread(imagePath)
        val image: Mat = originalImage.clone()
        val pathList = imagePath.split(".").toMutableList()
        pathList[pathList.size - 2] = pathList[pathList.size - 2] + "-new"
        val newPath = pathList.joinToString(".")


        var detections: MatOfRect = MatOfRect()

        faceDetector?.detectMultiScale(image, detections, 1.2)

        Log.i("FACE_DETECTION", "${detections.toList().size}")
        Log.i("FACE_DETECTION", detections.toString())

        val rects :List<Rect> = detections.toList()
        val rect = rects.get(0)

        val cropped: Mat = Mat(image, rect)
        resize(cropped, cropped, Size(48.0, 48.0))
        val bitmap: Bitmap = Bitmap.createBitmap(cropped.cols(), cropped.rows(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(cropped, bitmap)
        val resizedImage = Bitmap.createScaledBitmap(bitmap, 48, 48, true)

        val inputTensor: Tensor = TensorImageUtils.bitmapToFloat32Tensor(resizedImage, floatArrayOf(0.03F, 0.03F, 0.03F), floatArrayOf(1.018F, 1.018F, 1.018F));
        Log.i("INPUT TENSOR", "${inputTensor.shape()}")

        val outputTensor: Tensor = module?.forward(IValue.from(inputTensor))?.toTensor() ?: inputTensor
        val scores: FloatArray = outputTensor.dataAsFloatArray

        Log.i("SCORES", "${scores.toString()}")
        // searching for the index with maximum score
        // searching for the index with maximum score
        var maxScore: Float = -Float.MAX_VALUE
        var maxScoreIdx = -1
        for (i in 0 until scores.size) {
            if (scores[i] > maxScore) {
                maxScore = scores[i]
                maxScoreIdx = i
            }
        }

        val classes: Array<String> = arrayOf("fear", "angry", "happy", "neutral", "surprise", "disgust", "sad")
        val prediction = classes[maxScoreIdx]

        Log.i("OUTPUT PREDICTION", "PREDICTED OUTPUT CLASS => ${maxScoreIdx}")
        Log.i("OUTPUT PREDICTION", "PREDICTED OUTPUT => ${prediction}")

        putText(image, prediction, Point(rect.x.toDouble(), (rect.y.toDouble() - 10.0)), Core.FONT_HERSHEY_SIMPLEX, 2.0, Scalar(0.0, 255.0, 0.0, 255.0))
        rectangle(image, Point(rect.x.toDouble(), rect.y.toDouble()), Point((rect.x + rect.width).toDouble(), (rect.y + rect.height).toDouble()), Scalar(0.0, 255.0, 0.0, 255.0), 5, 4, 0)


        imwrite(newPath, image)
        val result: MutableList<String> = ArrayList()
        val elapsedTime = (System.nanoTime() - startTime) / 1000000
        result.add(newPath)
        result.add(prediction)
        result.add(elapsedTime.toString())
        return result
    }
}
