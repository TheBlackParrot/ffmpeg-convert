# ffmpeg-convert
ffmpeg-convert is a bash script to batch convert a folder of audio files to various audio formats.  
Configuration is done within the script.  

### Supported output formats
* MP3
* OGG
* Opus
* AAC/M4A
* WAV
* FLAC  

Supported input formats depend on the flags given when ffmpeg was compiled, and the available libraries.

### To do:
1. Add support for looking through directories recursively. (optional)
2. Add support for moving files to a different directory after ffmpeg finishes. (optional)
3. Add the ability to look for only certain filetypes. (optional)
4. Allow for multiple instances of ffmpeg to run at once.
5. Add support for using individual files rather than directories.

### Bugs:
* Filenames with multiple periods are cut off after the first period.  
(has to do with extension removing)