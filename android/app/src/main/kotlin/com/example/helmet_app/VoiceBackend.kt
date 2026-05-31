package com.example.helmet_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class VoiceBackend(private val context: Context, flutterEngine: FlutterEngine) :
    RecognitionListener, TextToSpeech.OnInitListener {

    companion object {
        private const val TAG = "VoiceBackend"
    }

    private val methodChannel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger, "com.helmet.app/voice"
    )
    private val eventChannel = EventChannel(
        flutterEngine.dartExecutor.binaryMessenger, "com.helmet.app/voice_events"
    )
    private var eventSink: EventChannel.EventSink? = null

    private var speechRecognizer: SpeechRecognizer? = null
    private var tts: TextToSpeech? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // STT state tracking
    private var isRecognizerBusy = false  // true from startListening until onResults/onError

    // TTS state
    private var isTtsInitialized = false

    init {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeStt" -> {
                    initializeStt()
                    result.success(true)
                }
                "startListening" -> {
                    startListening()
                    result.success(null)
                }
                "stopListening" -> {
                    stopListening()
                    result.success(null)
                }
                "cancelListening" -> {
                    cancelListening()
                    result.success(null)
                }
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    speak(text)
                    result.success(null)
                }
                "setSpeechRate" -> {
                    val rate = call.argument<Double>("rate") ?: 1.0
                    tts?.setSpeechRate(rate.toFloat())
                    result.success(null)
                }
                "setVolume" -> {
                    // Android TTS doesn't have a global volume API; we just use system volume.
                    result.success(null)
                }
                "stopSpeaking" -> {
                    tts?.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        tts = TextToSpeech(context, this)
    }

    // ---------- STT ----------

    private fun initializeStt() {
        // No-op: we create/destroy the recognizer in startListening/onResults/onError
        // to guarantee a clean state every time.
        Log.d(TAG, "initializeStt called (no-op, recognizer created on demand)")
    }

    private fun startListening() {
        mainHandler.post {
            if (isRecognizerBusy) {
                Log.w(TAG, "startListening ignored: recognizer is still busy")
                return@post
            }

            // Destroy any previous instance to guarantee clean state
            speechRecognizer?.destroy()
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            speechRecognizer?.setRecognitionListener(this)

            isRecognizerBusy = true

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                )
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, context.packageName)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            }
            speechRecognizer?.startListening(intent)
            sendEvent(mapOf("type" to "status", "value" to "listening"))
        }
    }

    private fun stopListening() {
        mainHandler.post {
            // Tell the recognizer to stop capturing audio.
            // It will still fire onResults() or onError() when done transcribing.
            // We do NOT reset isRecognizerBusy here — that happens in the callbacks.
            speechRecognizer?.stopListening()
        }
    }

    private fun cancelListening() {
        mainHandler.post {
            // Hard cancel: immediately drop everything.
            isRecognizerBusy = false
            speechRecognizer?.cancel()
            speechRecognizer?.destroy()
            speechRecognizer = null
            sendEvent(mapOf("type" to "status", "value" to "notListening"))
        }
    }

    // ---------- TTS ----------

    private fun speak(text: String) {
        if (!isTtsInitialized) {
            Log.w(TAG, "speak ignored: TTS not initialized yet")
            return
        }
        val utteranceId = java.util.UUID.randomUUID().toString()
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale.US
            isTtsInitialized = true
            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {}
                override fun onDone(utteranceId: String?) {
                    sendEvent(mapOf("type" to "ttsComplete"))
                }
                override fun onError(utteranceId: String?) {
                    sendEvent(mapOf("type" to "ttsComplete"))
                }
            })
            Log.d(TAG, "TTS initialized successfully")
        } else {
            Log.e(TAG, "TTS initialization failed with status: $status")
        }
    }

    // ---------- RecognitionListener ----------

    override fun onReadyForSpeech(params: Bundle?) {
        Log.d(TAG, "onReadyForSpeech")
    }

    override fun onBeginningOfSpeech() {
        Log.d(TAG, "onBeginningOfSpeech")
    }

    override fun onRmsChanged(rmsdB: Float) {
        sendEvent(mapOf("type" to "soundLevel", "level" to rmsdB.toDouble()))
    }

    override fun onBufferReceived(buffer: ByteArray?) {}

    override fun onEndOfSpeech() {
        Log.d(TAG, "onEndOfSpeech")
    }

    override fun onError(error: Int) {
        Log.w(TAG, "onError: $error")
        isRecognizerBusy = false
        // Destroy the recognizer so the next startListening gets a fresh one
        speechRecognizer?.destroy()
        speechRecognizer = null
        sendEvent(mapOf("type" to "error", "code" to error))
        sendEvent(mapOf("type" to "status", "value" to "notListening"))
    }

    override fun onResults(results: Bundle?) {
        isRecognizerBusy = false
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        val text = matches?.firstOrNull() ?: ""
        Log.d(TAG, "onResults: '$text'")
        // Destroy the recognizer so the next startListening gets a fresh one
        speechRecognizer?.destroy()
        speechRecognizer = null
        sendEvent(mapOf("type" to "result", "text" to text, "isFinal" to true))
        sendEvent(mapOf("type" to "status", "value" to "notListening"))
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        val text = matches?.firstOrNull() ?: ""
        if (text.isNotEmpty()) {
            sendEvent(mapOf("type" to "result", "text" to text, "isFinal" to false))
        }
    }

    override fun onEvent(eventType: Int, params: Bundle?) {}

    // ---------- Helpers ----------

    private fun sendEvent(event: Map<String, Any>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }
}
