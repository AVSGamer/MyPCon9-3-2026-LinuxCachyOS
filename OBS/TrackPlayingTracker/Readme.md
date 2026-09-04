To explain the script in this directory simply.
It autoruns on user login in the background via the OS startup settings.
It checks if there is any media playing every 2 seconds via a terminal command utility which in this case is "playerctl" you can replace this with any other utility you want to use.
Then via that utility we are also able to get the metadata of the track/media playing such as title, artist, and album and even albumArt, all via terminal as well.
The outputs of those are saved into a local file, in this case "~/" or your user's Home Directory as track_image.png & track_texts.txt or something similar.
Then those are pulled by your OBS or Streaming App as a local file to display to your stream's video feed or overlay. Image Source and Text Source..
