-- =====================================================================
-- Tool Name: New High Quality Voice & Video Recorder 2026
-- Version: 8.0 (Dedicated Video Record Button & Auto-Restart Update)
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

local updateURL = "https://raw.githubusercontent.com/kumaraditiya144-design/aditya/main/verson.txt"
local downloadURL = "https://raw.githubusercontent.com/kumaraditiya144-design/aditya/main/main.lua"
local defaultVersion = "8.0"
local currentDir = "/storage/emulated/0/解说/Tools/high quality voice recorder 2026"
local mainPath = currentDir .. "/main.lua"
local versionPath = currentDir .. "/version.txt"

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
    countdownTime = "3 Seconds",
    videoQuality = "1080p (Full HD)"
}

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

local function trim(s)
    if s == nil then return "" end
    return tostring(s):gsub("^%s*(.-)%s*$", "%1")
end

local function getCurrentVersion()
    local f = io.open(versionPath, "r")
    if f then
        local ver = f:read("*a")
        f:close()
        if ver then return trim(ver) end
    end
    return defaultVersion
end

local function restartTool()
    pcall(function()
        if mainDlg then mainDlg.dismiss() end
        local context = activity or service
        if context then
            local intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName())
            if intent then
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                context.startActivity(intent)
            end
        end
    end)
end

local function checkUpdate()
    local currentVersion = getCurrentVersion()
    local url = updateURL .. "?v=" .. os.time()
    
    Http.get(url, function(code, response)
        if code == 200 and response then
            local onlineVersion = trim(tostring(response))
            
            if onlineVersion ~= "" and onlineVersion ~= currentVersion then
                Handler(Looper.getMainLooper()).post(Runnable{run=function()
                    pcall(function()
                        playNotification()
                        local updateAlertDlg = AlertDialog.Builder(service or activity)
                        updateAlertDlg.setTitle("🚀 New Update Available!")
                        
                        local whatsNewText = "New Version: " .. onlineVersion .. "\nCurrent Version: " .. currentVersion .. 
                        "\n\n✨ What's New in v" .. onlineVersion .. ":\n" ..
                        "• Added Dedicated Video Start Button\n" ..
                        "• Auto-Restart After Update\n" ..
                        "• Enhanced CSR Screen Reader Compatibility\n\n" ..
                        "Do you want to update now?"
                        
                        updateAlertDlg.setMessage(whatsNewText)
                        updateAlertDlg.setPositiveButton("Update Now", {onClick=function(v)
                            v.dismiss()
                            Toast.makeText(service or activity, "Downloading & Installing...", 0).show()
                            
                            Http.get(downloadURL, function(c, content)
                                if c == 200 and content then
                                    local f = io.open(mainPath, "w")
                                    if f then 
                                        f:write(content) 
                                        f:close() 
                                    end
                                    
                                    local vf = io.open(versionPath, "w")
                                    if vf then 
                                        vf:write(onlineVersion) 
                                        vf:close() 
                                    end
                                    
                                    Toast.makeText(service or activity, "Updated successfully! Restarting...", 1).show()
                                    Handler().postDelayed(Runnable({
                                        run = function()
                                            restartTool()
                                        end
                                    }, 1000))
                                else
                                    Toast.makeText(service or activity, "Failed to download update file", 0).show()
                                end
                            end)
                        end})
                        updateAlertDlg.setNegativeButton("Later", nil)
                        local d1 = updateAlertDlg.create()
                        pcall(function() d1.getWindow().setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end)
                        d1.setCancelable(false)
                        d1.show()
                    end)
                end})
            end
        end
    end)
end

pcall(function()
    Thread(Runnable{
        run = function()
            checkUpdate()
        end
    }).start()
end)

function showMainTool()
    playNotification()

    if mainDlg then
        pcall(function() mainDlg.dismiss() end)
    end
    
    mainDlg = LuaDialog(activity or service)
    mainDlg.setTitle("HQ Recorder & Video Suite v" .. getCurrentVersion())
    
    local layout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Developer: Aditya poddar | v" .. getCurrentVersion(),
            textSize = "15sp",
            textColor = 0xFF555555,
            layout_marginBottom = "15dp",
            gravity = Gravity.CENTER,
        },
        {
            TextView,
            text = "Select Audio Format:",
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
            text = "Settings & Guidance",
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
            text = "Pause Recording",
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
            text = "Start Audio Recording",
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
            text = "Professional Video Recorder",
            textSize = "16sp",
            layout_width = "fill",
            layout_height = "wrap",
            layout_marginBottom = "10dp",
            onClick = function()
                showVideoRecorderDialog()
            end,
        },
        {
            Button,
            text = "About & Guide",
            textSize = "16sp",
            layout_width = "fill",
            layout_height = "wrap",
            layout_marginBottom = "10dp",
            onClick = function()
                showAboutDialog()
            end,
        },
        {
            Button,
            text = "Exit & Close",
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
    setDlg.setTitle("Settings & Guidance Options")
    
    local setLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "20dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            Switch,
            id = "noiseSwitch",
            text = "Noise Cancellation",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            checked = appSettings.noiseCancellation,
        },
        {
            Switch,
            id = "monitorSwitch",
            text = "Headphone Monitoring",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            checked = appSettings.headphoneMonitor,
        },
        {
            Switch,
            id = "guidanceSwitch",
            text = "TalkBack/CSR Guidance Mode",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            checked = appSettings.guidanceMode,
        },
        {
            TextView,
            text = "Video Quality Selector:",
            textSize = "13sp",
            layout_marginBottom = "5dp",
        },
        {
            Spinner,
            id = "videoQualitySpinner",
            layout_width = "fill",
            layout_marginBottom = "10dp",
        },
        {
            TextView,
            text = "Countdown Timer (Video Capture):",
            textSize = "13sp",
            layout_marginBottom = "5dp",
        },
        {
            Spinner,
            id = "countdownSpinner",
            layout_width = "fill",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = "Save Settings",
            textSize = "15sp",
            layout_width = "fill",
            onClick = function()
                appSettings.noiseCancellation = setViews.noiseSwitch.isChecked()
                appSettings.headphoneMonitor = setViews.monitorSwitch.isChecked()
                appSettings.guidanceMode = setViews.guidanceSwitch.isChecked()
                print("Settings Saved Successfully!")
                setDlg.dismiss()
            end,
        },
    }
    
    setViews = {}
    local setView = loadlayout(setLayout, setViews)
    
    local qualityOptions = {"1080p (Full HD)", "720p (HD)", "480p (SD)"}
    local qAdapter = ArrayAdapter(activity or service, android.R.layout.simple_spinner_item, qualityOptions)
    qAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    setViews.videoQualitySpinner.setAdapter(qAdapter)
    
    for i, v in ipairs(qualityOptions) do
        if v == appSettings.videoQuality then
            setViews.videoQualitySpinner.setSelection(i - 1)
        end
    end
    
    setViews.videoQualitySpinner.onItemSelectedListener = {
        onItemSelected = function(parent, v, position, id)
            appSettings.videoQuality = qualityOptions[position + 1]
        end,
        onNothingSelected = function(parent) end
    }
    
    local countOptions = {"3 Seconds", "5 Seconds"}
    local letAdapter = ArrayAdapter(activity or service, android.R.layout.simple_spinner_item, countOptions)
    letAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    setViews.countdownSpinner.setAdapter(letAdapter)
    
    for i, v in ipairs(countOptions) do
        if v == appSettings.countdownTime then
            setViews.countdownSpinner.setSelection(i - 1)
        end
    end
    
    setViews.countdownSpinner.onItemSelectedListener = {
        onItemSelected = function(parent, v, position, id)
            appSettings.countdownTime = countOptions[position + 1]
        end,
        onNothingSelected = function(parent) end
    }
    
    setDlg.setView(setView)
    setDlg.show()
end

function showVideoRecorderDialog()
    local vidDlg = LuaDialog(activity or service)
    vidDlg.setTitle("Pro Video Recorder Suite")
    
    local vidLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Quality: " .. appSettings.videoQuality .. "\nCountdown: " .. appSettings.countdownTime .. "\nGuidance: Active",
            textSize = "14sp",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = "🎬 Start Video Recording (Dedicated)",
            textSize = "15sp",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            onClick = function()
                vidDlg.dismiss()
                if appSettings.guidanceMode then
                    print("Guidance: Starting " .. appSettings.countdownTime .. " countdown for video recording...")
                end
                
                local delayTime = 3000
                if appSettings.countdownTime == "5 Seconds" then
                    delayTime = 5000
                end
                
                Toast.makeText(service or activity, "Recording will start in " .. appSettings.countdownTime, 0).show()
                
                Handler().postDelayed(Runnable({
                    run = function()
                        pcall(function()
                            playNotification()
                            local intent = Intent(android.provider.MediaStore.ACTION_VIDEO_CAPTURE)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            local ctx = activity or service
                            if ctx then
                                pcall(function() ctx.startActivity(intent) end)
                            end
                        end)
                        
                        Handler().postDelayed(Runnable({
                            run = function()
                                showVideoPreviewDialog()
                            end
                        }, 2000))
                    end
                }, delayTime))
            end,
        },
        {
            Button,
            text = "Back to Main Menu",
            textSize = "15sp",
            layout_width = "fill",
            onClick = function()
                vidDlg.dismiss()
            end,
        },
    }
    vidDlg.setView(loadlayout(vidLayout))
    vidDlg.show()
end

function showVideoPreviewDialog()
    pcall(function()
        local pDlg = LuaDialog(activity or service)
        pDlg.setTitle("Video Recording Manager")
        
        local pLayout = {
            LinearLayout,
            orientation = "vertical",
            padding = "25dp",
            layout_width = "fill",
            layout_height = "wrap",
            {
                TextView,
                text = "Target Quality: " .. appSettings.videoQuality .. "\nChoose an action below:",
                textSize = "14sp",
                layout_marginBottom = "15dp",
            },
            {
                Button,
                text = "Open Gallery / View Videos",
                textSize = "15sp",
                layout_width = "fill",
                layout_marginBottom = "10dp",
                onClick = function()
                    Toast.makeText(service or activity, "Opening gallery...", 0).show()
                    local intent = Intent(Intent.ACTION_VIEW)
                    intent.setType("video/*")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    (activity or service).startActivity(intent)
                end,
            },
            {
                Button,
                text = "Confirm & Save Settings (" .. appSettings.videoQuality .. ")",
                textSize = "15sp",
                layout_width = "fill",
                layout_marginBottom = "10dp",
                onClick = function()
                    pDlg.dismiss()
                    Toast.makeText(service or activity, "Video configuration saved successfully!", 1).show()
                    showMainTool()
                end,
            },
            {
                Button,
                text = "Back to Menu",
                textSize = "15sp",
                layout_width = "fill",
                onClick = function()
                    pDlg.dismiss()
                    showMainTool()
                end,
            },
        }
        pDlg.setView(loadlayout(pLayout))
        pDlg.setCancelable(false)
        local dialogWindow = pDlg.create()
        pcall(function() dialogWindow.getWindow().setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end)
        dialogWindow.show()
    end)
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
    
    if views and views.pauseResumeBtn and views.startStopBtn then
        views.pauseResumeBtn.setVisibility(View.VISIBLE)
        views.pauseResumeBtn.setText("Pause Recording")
        views.startStopBtn.setText("Stop Recording")
    end
    
    if appSettings.guidanceMode then
        print("Guidance: Audio recording started successfully.")
    else
        print("Recording Started!")
    end
end

function togglePauseResume()
    pcall(function()
        if android.os.Build.VERSION.SDK_INT >= 24 then
            if not isPaused then
                mediaRecorder.pause()
                isPaused = true
                if views and views.pauseResumeBtn then views.pauseResumeBtn.setText("Resume Recording") end
                print("Paused")
            else
                mediaRecorder.resume()
                isPaused = false
                if views and views.pauseResumeBtn then views.pauseResumeBtn.setText("Pause Recording") end
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
        views.startStopBtn.setText("Start Audio Recording")
        views.pauseResumeBtn.setVisibility(View.GONE)
    end
    
    showPreviewBeforeSaveDialog()
end

function showPreviewBeforeSaveDialog()
    local prevDlg = LuaDialog(activity or service)
    prevDlg.setTitle("Preview HD Audio Recording")
    
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
        
        let bis = BufferedInputStream(FileInputStream(audioFilePath))
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
    aboutDlg.setTitle("About & Guide")
    
    local aboutLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Tool: HQ Recorder & Video Suite\nVersion: " .. getCurrentVersion() .. "\nDeveloper: Aditya poddar\n\nFeatures:\n- Dedicated Video Start Button.\n- Auto-Restart Update Feature.",
            textSize = "14sp",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = "Check for Update",
            textSize = "15sp",
            layout_width = "fill",
            layout_height = "wrap",
            layout_marginBottom = "10dp",
            onClick = function()
                checkUpdate()
                print("Checking for updates...")
            end,
        },
        {
            Button,
            text = "Close About",
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

showMainTool()