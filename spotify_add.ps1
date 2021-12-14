$playlistId = 'playlist_id_goes_here'
$authToken = 'dev_console_oauth_token'
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($clientId):$clientSecret"))

$headers = @{
    'Authorization' = 'Bearer ' + $authToken
}

$songArray = Get-ChildItem -Path 'C:\Users\Kevin\Desktop\Techno & House\2021 House' -File -Name
$i = 0
do {
    #currently doesn't work for arrays of only 1 item
    #loop handles batch of 100 tracks at a time since this is a limit imposed by spotify
    [array] $playlistBatch = foreach($song in $songArray[$i..(($i += 100) - 1)]) {
        #my filenames typically follow the format '[bpm] - [artist(s)] - [track title]'
        #but I have to filter out some characters and words that spotify doesn't like in the search
        $song = $song.replace("&","").replace("'","").replace("(","").replace(")","").replace(",","").replace("Extended","").replace("Feat.","")
        $artist = $song.split('-')[1]
        $track = (([io.fileinfo]$song).basename).split('-')[2]
        $searchUri = "https://api.spotify.com/v1/search?q=artist:" + [System.Web.HttpUtility]::UrlEncode($artist) + "+track:" + [System.Web.HttpUtility]::UrlEncode($track) + "&type=track&limit=1"
        try {
            $response = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $headers -ContentType 'application/json'
            if ($response.tracks.items.id) {
                "spotify:track:" + $response.tracks.items.id
            }
        } catch {
            Write-Host "Status: " $_.Exception.Response.StatusCode.value__ $_.Exception.Response.StatusDescription
        }
    }
    $playlistUri = 'https://api.spotify.com/v1/playlists/' + $playlistId + '/tracks'
    $body = @{
        uris = $playlistBatch
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri $playlistUri -Method Post -Headers $headers -Body $body -ContentType 'application/json'
    } catch {
        Write-Host "Status: " $_.Exception.Response.StatusCode.value__ $_.Exception.Response.StatusDescription
    }
} until ($i -gt $songArray.Count -1)
