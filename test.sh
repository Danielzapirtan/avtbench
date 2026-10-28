#! /usr/bin/env bash

DEVICE=cpu
odir=$HOME/transcriptions
VER=3.12

if ! command -v python$VER &>/dev/null; then
	brew install python@$VER
fi
mkdir -p $odir
python$VER -m venv venv
source venv/bin/activate
export VIRTUAL_ENV
python$VER -m pip install --upgrade pip
brew install ffmpeg-full
pip install -r requirements.txt
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip

# 1. Install the package without resolving any dependencies
python -m pip install --no-deps whispermlx

# 2. Install its declared dependencies, skipping pyannote*
python -m pip show whispermlx \
  | sed -n 's/^Requires: //p' \
  | tr ',' '\n' \
  | sed 's/^ *//' \
  | grep -vi '^pyannote' \
  | xargs python -m pip install

# 3. Verify pyannote is absent and the package still imports
python -m pip list | grep -i pyannote || echo "pyannote not installed"
python -c "import whispermlx; print('ok')"

# Note: if the import fails on pyannote, that code path (diarization and/or
# pyannote-based VAD) is hard-required. Check the project's docs for a
# non-pyannote VAD option, or use plain transcription only.
whispermlx --help
for AUDIO_FILE in input*.mp4; do
	whispermlx "$AUDIO_FILE" --compression_ratio_threshold 2.4 --condition_on_previous_text False --device $DEVICE --language ro --logprob_threshold -1.0 --model large-v3 --no_speech_threshold 0.6 --output_dir $odir --output_format txt
	ofile=$odir/$(basename $AUDIO_FILE | sed -e "s/\.mp4//g").txt
	echo "=== Transcription"
	cat $ofile
	echo "==="
done
