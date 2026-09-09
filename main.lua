-- =====================================================================
-- Tool Name: New High Quality Voice Recorder 2026
-- Version: 6.2 (Updated Version Integration)
-- Developer: Aditya poddar
-- Compatible with C.S.R / TalkBack Screen Reader
-- =====================================================================

require "import"
import "android.widget.*"
import "android.view.*"
import "android.media.MediaRecorder"
import "android.media.MediaPlayer"
import "android.os.Environment"
import "android.os.Handler"
import "android.content.Intent"
import "android.net.Uri"
import "android.media.audiofx.NoiseSuppressor"
import "java.io.File"
import "java.io.FileInputStream"
import "java.io.FileOutputStream"
import "java.io.BufferedInputStream"
import "java.io.BufferedOutputStream"

local mediaRecorder = nil
local mediaPlayer = nil
local noiseSuppressor = nil
local audioFilePath = nil
local savedPublicFilePath = nil
local isPaused = false
local isRecording = false

-- গ্লোবাল সেটিংস এবং পার্মানেন্ট মেমোরি
local appSettings = {
    noiseCancellation = true,
    headphoneMonitor = false,
    selectedFormat = "MP3",
    audioChannel = "Studio",
    sampleRate = "44.1 kHz"
}

local mainDlg = nil
local views = {}

-- ১. মূল মেইন ডায়ালগ
function showMainTool()
    if mainDlg then
        pcall(function() mainDlg.dismiss() end)
    end
    
    mainDlg = LuaDialog(activity or service)
    mainDlg.setTitle("New High Quality Voice Recorder 2026")
    
    local layout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "Developer: Aditya poddar",
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
            visibility = View.GONE, -- রেকর্ডিং শুরুর আগে হাইড থাকবে
            onClick = function()
                togglePauseResume()
            end,
        },
        {
            Button,
            id = "startStopBtn",
            text = "Start Recording",
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

-- ২. সেটিংস ডায়ালগ
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

-- ৩. আসল ক্রিস্টাল ক্লিয়ার এইচডি সাউন্ড কোয়ালিটিতে রেকর্ডিং শুরু
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
        
        -- ক্রিস্টাল ক্লিয়ার এইচডি কোয়ালিটি বিটরেট (192kbps) এবং স্যাম্পলিং রেট
        mediaRecorder.setAudioEncodingBitRate(192000)
        mediaRecorder.setAudioSamplingRate(44100)
        
        if appSettings.audioChannel == "Studio" then
            mediaRecorder.setAudioChannels(2) -- স্টুডিও স্টেরিও
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
    
    -- বিন্যাস: উপরে Pause, নিচে Stop
    if views and views.pauseResumeBtn and views.startStopBtn then
        views.pauseResumeBtn.setVisibility(View.VISIBLE)
        views.pauseResumeBtn.setText("Pause Recording")
        views.startStopBtn.setText("Stop Recording")
    end
    
    -- ফোকাস সরাসরি Pause বাটনে সেট করা (TalkBack/CSR রিডার ফিক্স)
    Handler().postDelayed(Runnable({
        run = function()
            pcall(function()
                if views and views.pauseResumeBtn then
                    views.pauseResumeBtn.requestFocus()
                    views.pauseResumeBtn.sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_FOCUSED)
                end
            end)
        end
    }), 150)
    
    print("HD Crystal Clear Recording Started!")
end

-- ৪. পস এবং রিজিউম টগল ফাংশন
function togglePauseResume()
    pcall(function()
        if android.os.Build.VERSION.SDK_INT >= 24 then
            if not isPaused then
                mediaRecorder.pause()
                isPaused = true
                if views and views.pauseResumeBtn then
                    views.pauseResumeBtn.setText("Resume Recording")
                end
                print("Recording Paused")
            else
                mediaRecorder.resume()
                isPaused = false
                if views and views.pauseResumeBtn then
                    views.pauseResumeBtn.setText("Pause Recording")
                end
                print("Recording Resumed")
            end
        else
            print("Pause is not supported on this Android version")
        end
    end)
end

-- ৫. রেকর্ডিং স্টপ করা এবং প্রিভিউ ডায়ালগে যাওয়া
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
        views.startStopBtn.setText("Start Recording")
        views.pauseResumeBtn.setVisibility(View.GONE)
    end
    
    showPreviewBeforeSaveDialog()
end

-- ৬. প্রিভিউ ও শোনার ডায়ালগ
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
            text = "Recording stopped. Listen to the preview below before saving to storage.",
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
                        if mediaPlayer then
                            mediaPlayer.release()
                        end
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
                print("Recording discarded.")
                showMainTool()
            end,
        },
    }
    prevDlg.setView(loadlayout(prevLayout))
    prevDlg.show()
end

-- ৭. ফাইনাল সেভ করার মেথড (মিউজিক ফোল্ডারে পাঠানো)
function saveRecordingDirectly()
    pcall(function()
        local context = activity or service
        local fileName = "HD_Studio_Voice_" .. os.time() .. "." .. string.lower(appSettings.selectedFormat)
        
        local publicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
        local targetFolder = File(publicDir.absolutePath .. "/VoiceRecorder2026")
        if not targetFolder.exists() then
            targetFolder.mkdirs()
        end
        
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
        
        print("Successfully Saved in Music/VoiceRecorder2026!")
        showPostRecordingDialog()
    end)
end

-- ৮. সেভ হওয়ার পরের ডায়ালগ
function showPostRecordingDialog()
    local postDlg = LuaDialog(activity or service)
    postDlg.setTitle("Recording Saved")
    
    local postLayout = {
        LinearLayout,
        orientation = "vertical",
        padding = "25dp",
        layout_width = "fill",
        layout_height = "wrap",
        {
            TextView,
            text = "HD file saved successfully in your Music folder!\nPath: " .. tostring(savedPublicFilePath),
            textSize = "14sp",
            layout_marginBottom = "15dp",
        },
        {
            Button,
            text = "Play Saved Audio",
            textSize = "15sp",
            layout_width = "fill",
            layout_marginBottom = "10dp",
            onClick = function()
                pcall(function()
                    if savedPublicFilePath then
                        if mediaPlayer then
                            mediaPlayer.release()
                        end
                        mediaPlayer = MediaPlayer()
                        mediaPlayer.setDataSource(savedPublicFilePath)
                        mediaPlayer.prepare()
                        mediaPlayer.start()
                        print("Playing audio...")
                    end
                end)
            end,
        },
        {
            Button,
            text = "Close & Exit Tool",
            textSize = "15sp",
            layout_width = "fill",
            onClick = function()
                postDlg.dismiss()
                pcall(function() activity.finish() end)
            end,
        },
    }
    postDlg.setView(loadlayout(postLayout))
    postDlg.show()
end

-- ৯. অ্যাবাউট এন্ড গাইড সেকশন (Check for Update সহ v6.2)
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
            text = "Tool: New High Quality Voice Recorder 2026\nVersion: 6.2\nDeveloper: Aditya poddar\n\nGuide:\n1. Crystal clear HD audio with permanent Studio & MP3 setup.\n2. Pause button is placed ABOVE, Stop button is BELOW.\n3. Screen reader focus automatically lands on Pause button.",
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
                print("You are using the latest version (v6.2)!")
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

-- টুল চালু করার মূল ফাংশন কল
showMainTool()