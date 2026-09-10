-- =====================================================================
-- Tool Name: New High Quality Voice & Video Recorder 2026
-- Version: 7.4 (Auto-Update Fixed)
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
local defaultVersion = "7.3"
local currentDir = "/storage/emulated/0/解说/Tools/high quality voice recorder 2026"
local mainPath = currentDir .. "/main.lua"
local versionPath = currentDir .. "/version.txt"

local mediaRecorder = nil
local mediaPlayer = nil
local noiseSuppressor = nil
local audioFilePath = nil
local savedPublicFilePath = nil
local isPaused = false
local isRecording = false

local appSettings = {
    noiseCancellation = true,
    headphoneMonitor = true,
    selectedFormat = "MP3",
    audioChannel = "Studio"
}

local mainDlg = nil
local views = {}

local function playNotification()
    pcall(function()
        local tone = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
        tone.startTone(ToneGenerator.TONE_PROP_ACK, 100)
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
                        updateAlertDlg.setTitle("Update Available")
                        updateAlertDlg.setMessage("New Version: " .. onlineVersion .. "\nCurrent Version: " .. currentVersion .. "\n\nDo you want to update now?")
                        updateAlertDlg.setPositiveButton("Update Now", {onClick=function(v)
                            v.dismiss()
                            Toast.makeText(service or activity, "Downloading update...", 0).show()
                            
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
                                    
                                    local successDialog = AlertDialog.Builder(service or activity)
                                    successDialog.setTitle("Update Successful")
                                    successDialog.setMessage("Successfully updated to version " .. onlineVersion .. ".\n\nPlease restart the plugin.")
                                    successDialog.setPositiveButton("OK", {onClick=function(v2) v2.dismiss() end})
                                    local d2 = successDialog.create()
                                    pcall(function() d2.getWindow().setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end)
                                    d2.setCancelable(false)
                                    d2.show()
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
            text = "Select Recording Type (Format):",
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
            text = "Settings",
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
            text = "Video Recorder Suite",
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
    setDlg.setTitle("Settings")
    
    local setLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "20dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            Switch,
            id = "noiseSwitch",
            text = "Noise Cancellation (On/Off)",
            layout_width = "fill",
            layout_marginBottom = "12dp",
            checked = appSettings.noiseCancellation,
        },
        {
            Switch,
            id = "monitorSwitch",
            text = "Headphone Audio Monitoring (On/Off)",
            layout_width = "fill",
            layout_marginBottom = "12dp",
            checked = appSettings.headphoneMonitor,
        },
        {
            TextView,
            text = "Audio Channel (Studio Mode):",
            textSize = "13sp",
            layout_marginBottom = "5dp",
        },
        {
            Spinner,
            id = "channelSpinner",
            layout_width = "fill",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = "Save and Close Settings",
            textSize = "15sp",
            layout_width = "fill",
            onClick = function()
                appSettings.noiseCancellation = setViews.noiseSwitch.isChecked()
                appSettings.headphoneMonitor = setViews.monitorSwitch.isChecked()
                print("Settings Saved Successfully!")
                setDlg.dismiss()
            end,
        },
    }
    
    setViews = {}
    local setView = loadlayout(setLayout, setViews)
    
    local channels = {"Studio", "Mono"}
    local chanAdapter = ArrayAdapter(activity or service, android.R.layout.simple_spinner_item, channels)
    chanAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    setViews.channelSpinner.setAdapter(chanAdapter)
    
    for i, v in ipairs(channels) do
        if v == appSettings.audioChannel then
            setViews.channelSpinner.setSelection(i - 1)
        end
    end
    
    setViews.channelSpinner.onItemSelectedListener = {
        onItemSelected = function(parent, v, position, id)
            appSettings.audioChannel = channels[position + 1]
        end,
        onNothingSelected = function(parent) end
    }
    
    setDlg.setView(setView)
    setDlg.show()
end

function showVideoRecorderDialog()
    local vidDlg = LuaDialog(activity or service)
    vidDlg.setTitle("Video Recorder Suite")
    
    local vidLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Guide:\n1. Click the button below to open the system camera for video recording.\n2. Ensure proper lighting and audio stability before capturing.",
            textSize = "14sp",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = "Start Video Recording",
            textSize = "15sp",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            onClick = function()
                print("Guide: Position your camera steadily.")
                pcall(function()
                    local intent = Intent(android.provider.MediaStore.ACTION_VIDEO_CAPTURE)
                    if intent.resolveActivity(activity.getPackageManager()) ~= nil then
                        activity.startActivity(intent)
                    else
                        activity.startActivity(Intent(android.provider.MediaStore.INTENT_ACTION_VIDEO_CAMERA))
                    end
                end)
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
    
    print("Recording Started!")
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
    prevDlg.setTitle("Preview HD Recording")
    
    local prevLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Recording stopped. Listen to the preview below before saving.",
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
            text = "Save to Storage (Music Folder)",
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
        savedPublicFilePath = destFile.absolutePath
        
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
    aboutDlg.setTitle("About & Guide")
    
    local aboutLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Tool: HQ Recorder & Video Suite\nVersion: " .. getCurrentVersion() .. "\nDeveloper: Aditya poddar\n\nAuto-update system is active.",
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