#!/bin/sh

### CONFIGURATION ###
DIR="$PWD"																# directory with audio files. use $PWD to get the current directory.
OUT_LOCATION="/tmp/ffmpeg-output-$(date +%H%M%S_%m%d)"					# (default: "/tmp/ffmpeg-output-$(date +%H%M%S_%m%d)") folder for conversion/transcribing output
VALID_EXTENSIONS=("mp3" "wav" "ogg" "flac" "opus" "m4a" "aac")			# supported formats
OUT_EXTENSION="mp3"														# format to convert to
THREADS=8																# threads for the process (recommended to use the amount of CPU cores available)

# GLOBAL CODEC CONFIG
SAMPLE_RATE=44100					# sample rate in Hz
CHANNELS=2							# audio channels

# MP3 CODEC
MP3_BITRATE_TYPE="VBR"				# type of bitrate. CBR, VBR, or ABR
MP3_VBR_QUALITY=2					# quality of the output, lower is best, higher is worst. 0-9 are valid.
MP3_BITRATE="256k"					# bitrate for CBR/ABR
MP3_COMPRESSION_LEVEL=2				# (default: 2) compression level for output. highest is best, lower is worst. 0-9 are valid.

# OGG CODEC
OGG_BITRATE_TYPE="VBR"				# type of bitrate. ABR or VBR
OGG_VBR_QUALITY="6.0"				# higher is best, lower is worst. any number valid.
OGG_ABR_BITRATE="256k"				# bitrate for ABR
OGG_MINIMUM_BITRATE="8k"			# lowest bitrate the encoder is allowed to go to
OGG_MAXIMUM_BITRATE="320k"			# highest bitrate the encoder is allowed to go to (only affects ABR)

# OPUS CODEC
# note: 48000Hz sample rate is forced
# note: ID3 tags not preserved
OPUS_BITRATE_TYPE="VBR"				# type of bitrate. CBR, VBR, or CVBR (constrained VBR)
OPUS_BITRATE="224k"					# bitrate
OPUS_COMPRESSION_LEVEL=3			# (default: 9) compression level for output. highest is best, lower is worst. 0-10 are valid.
OPUS_FRAME_DURATION="20"			# (default: 20) duration of a frame in milliseconds. allowed values are 2.5, 5, 10, 20, 40, and 60.
OPUS_PACKET_LOSS=0					# (default: 0) expected percentage of packet loss

# AAC/M4A CODEC
# note: applies to both .m4a and .aac
AAC_BITRATE_TYPE="VBR"				# type of bitrate. ABR or VBR
AAC_ABR_BITRATE="224k"				# bitrate for ABR
AAC_VBR_QUALITY=400					# quality of the output, lower is worst, higher is best. 10-500 is reasonable.
AAC_PROFILE="aac_low"				# audio profiles. "aac_main", "aac_low" (default), "aac_ssr", or "aac_ltp"

# WAV CODEC
WAV_TYPE="pcm_s16le"				# (default: pcm_s16le) type of raw output. to get a list of valid options, use 'ffmpeg -formats | grep PCM'.

# FLAC CODEC
FLAC_COMPRESSION_LEVEL=8			# (default: 8) compression level for output. highest is worst, lower is best. 0-12 are valid.
FLAC_LPC_TYPE=3						# (default: 3) LPC algorithm (0: none, 1: fixed, 2: levinson, 3: cholesky)
FLAC_LPC_PASSES=2					# (default: 2) number of passes to use for Cholesky factorization during LPC analysis

### SCRIPT ###
### -DO NOT MODIFY- ###
TOTAL_FILES=0
CURRENT_POSITION=0

# getting amount of files to be converted
for FILE in "$DIR"/*
do
	FILENAME=$(basename "$FILE")
	EXT="${FILENAME##*.}"
	if [[ $VALID_EXTENSIONS =~ $EXT ]]; then
		TOTAL_FILES=$((TOTAL_FILES + 1))
	fi
done

# actually converting them
mkdir -p $OUT_LOCATION
for FILE in "$DIR"/*
do
	FILENAME=$(basename "$FILE")
	EXT="${FILENAME##*.}"
	OUT_FILENAME=${FILENAME%%.*}
	if [[ $VALID_EXTENSIONS =~ $EXT ]]; then
		CURRENT_POSITION=$((CURRENT_POSITION + 1))
		if [ $OUT_EXTENSION == $EXT ]; then
			echo "[$CURRENT_POSITION / $TOTAL_FILES] Transcribing $FILENAME..."
		else
			echo "[$CURRENT_POSITION / $TOTAL_FILES] Converting $FILENAME to $OUT_EXTENSION..."
		fi
		ffprobe "$FILE" 2>&1 | grep -A1 Duration
		case $OUT_EXTENSION in
			"mp3")
				case $MP3_BITRATE_TYPE in
					"CBR")
						PARAMETERS="-acodec libmp3lame -b:a $MP3_BITRATE -compression_level $MP3_COMPRESSION_LEVEL"
						;;
					"ABR")
						PARAMETERS="-acodec libmp3lame -b:a $MP3_BITRATE -compression_level $MP3_COMPRESSION_LEVEL -abr 1"
						;;
					"VBR")
						PARAMETERS="-acodec libmp3lame -q $MP3_VBR_QUALITY -compression_level $MP3_COMPRESSION_LEVEL"
						;;
				esac
				;;
			"ogg")
				case $OGG_BITRATE_TYPE in
					"ABR")
						PARAMETERS="-acodec libvorbis -b:a $OGG_ABR_BITRATE -minrate $OGG_MINIMUM_BITRATE -maxrate $OGG_MAXIMUM_BITRATE"
						;;
					"VBR")
						PARAMETERS="-acodec libvorbis -q:a $OGG_VBR_QUALITY -minrate $OGG_MINIMUM_BITRATE"
						;;
				esac
				;;
			"opus")
				case $OPUS_BITRATE_TYPE in
					"CBR")
						PARAMETERS="-acodec libopus -vbr off -compression_level $OPUS_COMPRESSION_LEVEL -b:a $OPUS_BITRATE -frame_duration $OPUS_FRAME_DURATION -packet_loss $OPUS_PACKET_LOSS"
						;;
					"VBR")
						PARAMETERS="-acodec libopus -vbr on -compression_level $OPUS_COMPRESSION_LEVEL -b:a $OPUS_BITRATE -frame_duration $OPUS_FRAME_DURATION -packet_loss $OPUS_PACKET_LOSS"
						;;
					"CVBR")
						PARAMETERS="-acodec libopus -vbr constrained -compression_level $OPUS_COMPRESSION_LEVEL -b:a $OPUS_BITRATE -frame_duration $OPUS_FRAME_DURATION -packet_loss $OPUS_PACKET_LOSS"
						;;
				esac
				;;
			"m4a" | "aac")
				echo "WARNING: AAC/M4A is an experimental codec! \'-strict -2\' was used to circumvent the warning."
				case $AAC_BITRATE_TYPE in
					"ABR")
						PARAMETERS="-strict -2 -acodec aac -b:a $AAC_ABR_BITRATE"
						;;
					"VBR")
						PARAMETERS="-strict -2 -acodec aac -profile:a $AAC_PROFILE -q:a $AAC_VBR_QUALITY"
						;;
				esac
				;;
			"wav")
				PARAMETERS="-acodec $WAV_TYPE"
				;;
			"flac")
				PARAMETERS="-acodec flac -compression_level $FLAC_COMPRESSION_LEVEL -lpc_type $FLAC_LPC_TYPE -lpc_passes $FLAC_LPC_PASSES"
				;;
		esac
		if [ $OUT_EXTENSION == "opus" ]; then
			ffmpeg -threads $THREADS -v quiet -stats -i "$FILE" $PARAMETERS -ar 48000 -ac $CHANNELS "$OUT_LOCATION/$OUT_FILENAME.$OUT_EXTENSION"
		else
			ffmpeg -threads $THREADS -v quiet -stats -i "$FILE" $PARAMETERS -ar $SAMPLE_RATE -ac $CHANNELS "$OUT_LOCATION/$OUT_FILENAME.$OUT_EXTENSION"
		fi
	else
		echo "$FILENAME is not a supported file..."
	fi
done
echo -e "\nComplete."

# TODO:
# get the libraries for each format, and their respective ffmpeg parameters