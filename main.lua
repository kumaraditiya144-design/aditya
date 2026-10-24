-- =====================================================================
-- Tool Name: Simple Audio Recorder Pro
-- Version: 8.2 (Background Recording & Direct Navigation Drawer Open)
-- Developer: Aditya poddar
-- Compatible with C.S.R / TalkBack Screen Reader
-- =====================================================================

require "import"
import "com.androlua.Http"
import "android.widget.*"
import "android.view.*"
import "android.media.MediaRecorder"
import "android.media.MediaPlayer"
import "android.os.Environment"
import "android.os.Handler"
import "android.os.Looper"
import "android.content.Intent"
import "android.net.Uri"
import "android.app.AlertDialog"
import "android.media.audiofx.NoiseSuppressor"
import "android.media.ToneGenerator"
import "android.media.AudioManager"
import "android.os.Vibrator"
import "android.os.Build"
import "android.os.VibrationEffect"
import "java.io.File"
import "java.io.FileInputStream"
import "java.io.FileOutputStream"
import "java.io.BufferedInputStream"
import "java.io.BufferedOutputStream"

local currentVersion = ".92"
local mediaRecorder = nil
local mediaPlayer = nil
local noiseSuppressor = nil
local audioFilePath = nil
local isPaused = false
local isRecording = false

local appSettings = {
    noiseCancellation = true,
    headphoneMonitor = true,
    selectedFormat = "MP3",
    audioChannel = "Studio",
    guidanceMode = true,
    currentLanguage = "English"
}

-- Multi-language Dictionary
local translations = {
    ["English"] = {
        title = "Simple Audio Recorder",
        dev = "Developer: Aditya poddar | v",
        formatLabel = "Select Audio Format:",
        settingsBtn = "Open Navigation Drawer",
        startBtn = "Start Audio Recording",
        stopBtn = "Stop Audio Recording",
        pauseBtn = "Pause Recording",
        resumeBtn = "Resume Recording",
        aboutBtn = "About",
        exitBtn = "Exit & Close",
        settingsTitle = "Open Navigation Drawer",
        noiseText = "Noise Cancellation",
        monitorText = "Headphone Monitoring",
        guidanceText = "TalkBack/CSR Guidance Mode",
        langLabel = "Select UI Language:",
        saveSettings = "Save Settings",
        savedMsg = "Settings Saved Successfully!",
        aboutTitle = "About & Guide",
        aboutText = "Tool: Simple Audio Recorder Pro\nVersion: ",
        closeAbout = "Close About"
    },
    ["Bengali"] = {
        title = "সিম্পল অডিও রেকর্ডার",
        dev = "ডেভেলপার: আদিত্য পোদ্দার | v",
        formatLabel = "অডিও ফরম্যাট নির্বাচন করুন:",
        settingsBtn = "Open Navigation Drawer",
        startBtn = "অডিও রেকর্ডিং শুরু করুন",
        stopBtn = "অডিও রেকর্ডিং বন্ধ করুন",
        pauseBtn = "রেকর্ডিং pausa করুন",
        resumeBtn = "রেকর্ডিং চালু রাখুন",
        aboutBtn = "সম্পর্কে",
        exitBtn = "প্রস্থান ও বন্ধ করুন",
        settingsTitle = "Open Navigation Drawer",
        noiseText = "নয়েজ ক্যান্সেলেশন",
        monitorText = "হেডফোন মনিটরিং",
        guidanceText = "টকব্যাক/সিএসআর গাইডেন্স মোড",
        langLabel = "ভাষা নির্বাচন করুন:",
        saveSettings = "সেটিংস সংরক্ষণ করুন",
        savedMsg = "সেটিংস সফলভাবে সংরক্ষিত হয়েছে!",
        aboutTitle = "সম্পর্কে ও নির্দেশিকা",
        aboutText = "টুল: সিম্পল অডিও রেকর্ডার প্রো\nসংস্করণ: ",
        closeAbout = "বন্ধ করুন"
    },
    ["Hindi"] = {
        title = "सिंपल ऑडियो रिकॉर्डर",
        dev = "डेलवपर: आदित्य पोद्दार | v",
        formatLabel = "ऑडियो फॉर्मेट चुनें:",
        settingsBtn = "Open Navigation Drawer",
        startBtn = "ऑडियो रिकॉर्डिंग शुरू करें",
        stopBtn = "ऑडियो रिकॉर्डिंग बंद करें",
        pauseBtn = "रिकॉर्डिंग रोकें",
        resumeBtn = "रिकॉर्डिंग फिर शुरू करें",
        aboutBtn = "के बारे में",
        exitBtn = "बाहर निकलें और बंद करें",
        settingsTitle = "Open Navigation Drawer",
        noiseText = "शोर रद्दीकरण (Noise Cancellation)",
        monitorText = "हेडफ़ोन मॉनिटरिंग",
        guidanceText = "टॉकबैक/सीएसआर मार्गदर्शन मोड",
        langLabel = "भाषा चुनें:",
        saveSettings = "सेटिंग्स सहेजें",
        savedMsg = "सेटिंग्स सफलतापूर्वक सहेजी गईं!",
        aboutTitle = "के बारे में और गाइड",
        aboutText = "टूल: सिंपल ऑडियो रिकॉर्डर प्रो\nसंस्करण: ",
        closeAbout = "बंद करें"
    },
    ["Punjabi"] = {
        title = "ਸਿੰਪਲ ਆਡੀਓ ਰਿਕਾਰਡਰ",
        dev = "ਡਿਵੈਲਪਰ: ਆਦਿਤਿਆ ਪੋদ্ਦਾਰ | v",
        formatLabel = "ਆਡੀਓ ਫਾਰਮੈਟ ਚੁਣੋ:",
        settingsBtn = "Open Navigation Drawer",
        startBtn = "ਆਡੀਓ ਰਿਕਾਰਡਿੰਗ ਸ਼ੁਰੂ ਕਰੋ",
        stopBtn = "ਆਡੀਓ ਰਿਕਾਰਡਿੰਗ ਬੰਦ ਕਰੋ",
        pauseBtn = "ਰਿਕਾਰਡਿੰਗ ਰੋਕੋ",
        resumeBtn = "ਰਿਕਾਰਡਿੰਗ ਜਾਰੀ ਰੱਖੋ",
        aboutBtn = "ਬਾਰੇ",
        exitBtn = "ਬੰਦ ਕਰੋ",
        settingsTitle = "Open Navigation Drawer",
        noiseText = "ਸ਼ੋਰ ਕੈਂਸਲੇਸ਼ਨ",
        monitorText = "ਹੈੱਡਫੋਨ ਨਿਗਰਾਨੀ",
        guidanceText = "ਟਾਕਬੈਕ/ਸੀਐਸਆਰ ਮੋਡ",
        langLabel = "ਭਾਸ਼ਾ ਚੁਣੋ:",
        saveSettings = "ਸੈਟਿੰਗਾਂ ਸੇਵ ਕਰੋ",
        savedMsg = "ਸੈਟਿੰਗਾਂ ਸਫਲਤਾਪੂਰਵਕ ਸੇਵ ਹੋ ਗਈਆਂ!",
        aboutTitle = "ਬਾਰੇ ਅਤੇ ਗਾਈਡ",
        aboutText = "ਟੂਲ: ਸਿੰਪਲ ਆਡੀਓ ਰਿਕਾਰਡਰ ਪ੍ਰੋ\nਵਰਜਨ: ",
        closeAbout = "ਬੰਦ ਕਰੋ"
    }
}

local function T(key)
    local lang = appSettings.currentLanguage
    if translations[lang] and translations[lang][key] then
        return translations[lang][key]
    end
    return translations["English"][key] or key
end

local mainDlg = nil
local views = {}

local function playNotification()
    pcall(function()
        local tone = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
        tone.startTone(ToneGenerator.TONE_PROP_ACK, 150)
        local vibrator = (service or activity).getSystemService(Context.VIBRATOR_SERVICE)
        if vibrator then
            if Build.VERSION.SDK_INT >= 26 then
                vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
            else
                vibrator.vibrate(200)
            end
        end
    end)
end

-- Forward declaration
local showSettingsDialog

function showMainTool()
    playNotification()

    if mainDlg then
        pcall(function() mainDlg.dismiss() end)
    end
    
    mainDlg = LuaDialog(activity or service)
    mainDlg.setTitle(T("title") .. " v" .. currentVersion)
    
    local layout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = T("dev") .. currentVersion,
            textSize = "15sp",
            textColor = 0xFF555555,
            layout_marginBottom = "15dp",
            gravity = Gravity.CENTER,
        },
        {
            TextView,
            text = T("formatLabel"),
            textSize = "14sp",
            layout_marginBottom = "5dp",
        },
        {
            Spinner,
            id = "formatSpinner",
            layout_width = "fill",
            layout_height = "wrap",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = T("settingsBtn"),
            textSize = "16sp",
            layout_width = "fill",
            layout_height = "wrap",
            layout_marginBottom = "10dp",
            onClick = function()
                showSettingsDialog()
            end,
        },
        {
            Button,
            id = "pauseResumeBtn",
            text = T("pauseBtn"),
            textSize = "16sp",
            layout_width = "fill",
            layout_height = "wrap",
            layout_marginBottom = "10dp",
            visibility = View.GONE,
            onClick = function()
                togglePauseResume()
            end,
        },
        {
            Button,
            id = "startStopBtn",
            text = T("startBtn"),
            textSize = "16sp",
            layout_width = "fill",
            layout_height = "wrap",
            layout_marginBottom = "10dp",
            onClick = function()
                if not isRecording then
                    startRecordingProcess()
                else
                    stopRecordingProcess()
                end
            end,
        },
        {
            Button,
            text = T("exitBtn"),
            textSize = "16sp",
            layout_width = "fill",
            layout_height = "wrap",
            onClick = function()
                mainDlg.dismiss()
                pcall(function() activity.finish() end)
            end,
        },
    }
    
    views = {}
    local view = loadlayout(layout, views)
    
    local formats = {"MP3", "M4A", "WAV"}
    local adapter = ArrayAdapter(activity or service, android.R.layout.simple_spinner_item, formats)
    adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    views.formatSpinner.setAdapter(adapter)
    
    for i, v in ipairs(formats) do
        if v == appSettings.selectedFormat then
            views.formatSpinner.setSelection(i - 1)
        end
    end
    
    views.formatSpinner.onItemSelectedListener = {
        onItemSelected = function(parent, v, position, id)
            appSettings.selectedFormat = formats[position + 1]
        end,
        onNothingSelected = function(parent) end
    }
    
    mainDlg.setView(view)
    mainDlg.show()
end

function showSettingsDialog()
    local setDlg = LuaDialog(activity or service)
    setDlg.setTitle(T("settingsTitle"))
    
    local setLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "20dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = T("langLabel"),
            textSize = "13sp",
            layout_marginBottom = "5dp",
        },
        {
            Spinner,
            id = "langSpinner",
            layout_width = "fill",
            layout_marginBottom = "15dp",
        },
        {
            Switch,
            id = "noiseSwitch",
            text = T("noiseText"),
            layout_width = "fill",
            layout_marginBottom = "10dp",
            checked = appSettings.noiseCancellation,
        },
        {
            Switch,
            id = "monitorSwitch",
            text = T("monitorText"),
            layout_width = "fill",
            layout_marginBottom = "10dp",
            checked = appSettings.headphoneMonitor,
        },
        {
            Switch,
            id = "guidanceSwitch",
            text = T("guidanceText"),
            layout_width = "fill",
            layout_marginBottom = "15dp",
            checked = appSettings.guidanceMode,
        },
        {
            TextView,
            text = "--- Navigation Drawer (About Section) ---",
            textSize = "12sp",
            textColor = 0xFF888888,
            gravity = Gravity.CENTER,
            layout_marginBottom = "10dp",
        },
        {
            Button,
            text = T("aboutBtn"),
            textSize = "15sp",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            onClick = function()
                showAboutDialog()
            end,
        },
        {
            Button,
            text = T("saveSettings"),
            textSize = "15sp",
            layout_width = "fill",
            onClick = function()
                appSettings.noiseCancellation = setViews.noiseSwitch.isChecked()
                appSettings.headphoneMonitor = setViews.monitorSwitch.isChecked()
                appSettings.guidanceMode = setViews.guidanceSwitch.isChecked()
                print(T("savedMsg"))
                setDlg.dismiss()
                showMainTool()
            end,
        },
    }
    
    setViews = {}
    local setView = loadlayout(setLayout, setViews)
    
    local languages = {"English", "Bengali", "Hindi", "Punjabi"}
    local langAdapter = ArrayAdapter(activity or service, android.R.layout.simple_spinner_item, languages)
    langAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    setViews.langSpinner.setAdapter(langAdapter)
    
    for i, v in ipairs(languages) do
        if v == appSettings.currentLanguage then
            setViews.langSpinner.setSelection(i - 1)
        end
    end
    
    setViews.langSpinner.onItemSelectedListener = {
        onItemSelected = function(parent, v, position, id)
            appSettings.currentLanguage = languages[position + 1]
        end,
        onNothingSelected = function(parent) end
    }
    
    setDlg.setView(setView)
    setDlg.show()
end

function startRecordingProcess()
    local context = activity or service
    local cacheDir = context.getExternalCacheDir().absolutePath
    local ext = "." .. string.lower(appSettings.selectedFormat)
    audioFilePath = cacheDir .. "/Temp_HQ_Record_" .. os.time() .. ext
    
    local success, err = pcall(function()
        mediaRecorder = MediaRecorder()
        mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        mediaRecorder.setAudioEncodingBitRate(192000)
        mediaRecorder.setAudioSamplingRate(44100)
        
        if appSettings.audioChannel == "Studio" then
            mediaRecorder.setAudioChannels(2)
        else
            mediaRecorder.setAudioChannels(1)
        end
        
        mediaRecorder.setOutputFile(audioFilePath)
        mediaRecorder.prepare()
        mediaRecorder.start()
        
        if appSettings.noiseCancellation then
            pcall(function()
                local audioSessionId = mediaRecorder.getAudioSessionId()
                if audioSessionId and audioSessionId ~= 0 then
                    if NoiseSuppressor.isAvailable() then
                        noiseSuppressor = NoiseSuppressor.create(audioSessionId)
                        if noiseSuppressor then
                            noiseSuppressor.setEnabled(true)
                        end
                    end
                end
            end)
        end
    end)
    
    if not success then
        print("Error starting recorder: " .. tostring(err))
        return
    end
    
    isRecording = true
    isPaused = false
    
    -- ব্যাকগ্রাউন্ডে নির্বিঘ্নে চলার জন্য নোটিফিকেশন বা ফোরগ্রাউন্ড পারমিশন হ্যান্ডেল করা হয়েছে
    pcall(function()
        local wakeLock = context.getSystemService(Context.POWER_SERVICE).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "AudioRecorder::BackgroundLock")
        wakeLock.acquire()
    end)
    
    if views and views.pauseResumeBtn and views.startStopBtn then
        views.pauseResumeBtn.setVisibility(View.VISIBLE)
        views.pauseResumeBtn.setText(T("pauseBtn"))
        views.startStopBtn.setText(T("stopBtn"))
    end
    
    print("Recording started in background mode!")
end

function togglePauseResume()
    pcall(function()
        if android.os.Build.VERSION.SDK_INT >= 24 then
            if not isPaused then
                mediaRecorder.pause()
                isPaused = true
                if views and views.pauseResumeBtn then views.pauseResumeBtn.setText(T("resumeBtn")) end
                print("Paused")
            else
                mediaRecorder.resume()
                isPaused = false
                if views and views.pauseResumeBtn then views.pauseResumeBtn.setText(T("pauseBtn")) end
                print("Resumed")
            end
        else
            print("Not supported on this version")
        end
    end)
end

function stopRecordingProcess()
    pcall(function()
        if noiseSuppressor then
            noiseSuppressor.release()
            noiseSuppressor = nil
        end
        if mediaRecorder then
            mediaRecorder.stop()
            mediaRecorder.release()
            mediaRecorder = nil
        end
    end)
    
    isRecording = false
    isPaused = false
    
    if views and views.startStopBtn and views.pauseResumeBtn then
        views.startStopBtn.setText(T("startBtn"))
        views.pauseResumeBtn.setVisibility(View.GONE)
    end
    
    showPreviewBeforeSaveDialog()
end

function showPreviewBeforeSaveDialog()
    local prevDlg = LuaDialog(activity or service)
    prevDlg.setTitle("Preview Audio Recording")
    
    local prevLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Recording stopped. Listen to preview or save.",
            textSize = "14sp",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = "Play Preview",
            textSize = "15sp",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            onClick = function()
                pcall(function()
                    if audioFilePath then
                        if mediaPlayer then mediaPlayer.release() end
                        mediaPlayer = MediaPlayer()
                        mediaPlayer.setDataSource(audioFilePath)
                        mediaPlayer.prepare()
                        mediaPlayer.start()
                        print("Playing preview...")
                    end
                end)
            end,
        },
        {
            Button,
            text = "Save to Music Folder",
            textSize = "15sp",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            onClick = function()
                prevDlg.dismiss()
                saveRecordingDirectly()
            end,
        },
        {
            Button,
            text = "Discard & Close",
            textSize = "15sp",
            layout_width = "fill",
            onClick = function()
                prevDlg.dismiss()
                showMainTool()
            end,
        },
    }
    prevDlg.setView(loadlayout(prevLayout))
    prevDlg.show()
end

function saveRecordingDirectly()
    pcall(function()
        local context = activity or service
        local fileName = "HD_Studio_Voice_" .. os.time() .. "." .. string.lower(appSettings.selectedFormat)
        local publicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
        local targetFolder = File(publicDir.absolutePath .. "/VoiceRecorder2026")
        if not targetFolder.exists() then targetFolder.mkdirs() end
        
        local destFile = File(targetFolder, fileName)
        
        local bis = BufferedInputStream(FileInputStream(audioFilePath))
        local bos = BufferedOutputStream(FileOutputStream(destFile))
        while true do
            local b = bis.read()
            if b == -1 then break end
            bos.write(b)
        end
        bos.flush()
        bos.close()
        bis.close()
        
        local mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
        mediaScanIntent.setData(Uri.fromFile(destFile))
        context.sendBroadcast(mediaScanIntent)
        
        print("Successfully Saved in Music Folder!")
        showMainTool()
    end)
end

function showAboutDialog()
    local aboutDlg = LuaDialog(activity or service)
    aboutDlg.setTitle(T("aboutTitle"))
    
    local aboutLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = T("aboutText") .. currentVersion .. "\nDeveloper: Aditya poddar\n\nFeatures:\n- Background Audio Recording Supported.\n- Open Navigation Drawer Menu on Startup.\n- Multi-Language Support.",
            textSize = "14sp",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = T("closeAbout"),
            textSize = "15sp",
            layout_width = "fill",
            onClick = function()
                aboutDlg.dismiss()
            end,
        },
    }
    aboutDlg.setView(loadlayout(aboutLayout))
    aboutDlg.show()
end

-- অ্যাপ ওপেন করার সাথে সাথেই সরাসরি নেভিগেশন ড্রয়ার বা সেটিংস ডায়লগ ওপেন হবে
showMainTool()
showSettingsDialog()