#! /usr/bin/env bash

DEVICE=cpu
odir=$HOME/transcriptions
VER=3.12

if ! command -v python$VER &>/dev/null; then
	brew install python@$VER
fi
mkdir -p $odir
rm -rf .venv
brew install ffmpeg
python$VER -m venv .venv
source .venv/bin/activate
export VIRTUAL_ENV
python$VER -m pip install --upgrade pip
rm -rf requirements.lock.txt
bash resolve_install.sh requirements_template.txt .venv
rm -rf requirements.lock.txt
bash resolve_install.sh requirements_template_mlx.txt .venv
pip check
source .venv/bin/activate
whispermlx --help
for AUDIO_FILE in input*.mp4; do
	whispermlx "$AUDIO_FILE" --compression_ratio_threshold 2.4 --condition_on_previous_text False --device $DEVICE --language ro --logprob_threshold -1.0 --model large-v3 --output_dir $odir --output_format txt
	ofile=$odir/$(basename $AUDIO_FILE | sed -e "s/\.mp4//g").txt
	echo "=== Transcription"
	cat $ofile
	echo "==="
done
