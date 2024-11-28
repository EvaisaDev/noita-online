

streaming = {
    apps =  {
        "obs32.exe", 
        "obs64.exe", 
        "obs.exe", 
        "xsplit.core.exe", 
        "livehime.exe", 
        "pandatool.exe", 
        "yymixer.exe", 
        "douyutool.exe", 
        "huomaotool.exe", 
        "dytool.exe", 
        "twitchstudio.exe", 
        "gamecaster.exe", 
        "evcapture.exe", 
        "kk.exe", 
        "streamlabs obs.exe"
    },
}

-- Function to check if a streaming app is running
streaming.IsStreaming = function()
    os.execute("tasklist > tasklist.txt")

    local file = io.open("tasklist.txt", "r")
    if not file then
        return false, "Unable to open tasklist.txt"
    end

    local content = file:read("*a")
    file:close()

    -- remove the file
    os.remove("tasklist.txt")

    for _, app in ipairs(streaming.apps) do
        if content:find(app) then
            return true, app
        end
    end
    

    return false, "No streaming apps are running"
end


return streaming