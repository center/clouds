.PHONY: all
all: clouds.webm

# Baked into repository to not make Github angry at us
#cut.mp4: RooftopCloudsH264.mp4
#	ffmpeg -y -i "$<" -ss 00:00:05 -t 00:00:09 -async 1 "$@"

cropped.mp4: cut.mp4
	ffmpeg -y -i "$<" -filter:v "crop=1920:800:0:0" "$@"

desaturated.mp4: cropped.mp4
	ffmpeg -y -i "$<" -vf "format=gray" -pix_fmt yuv420p "$@"

slomoi.mp4: desaturated.mp4
	ffmpeg -y -i "$<" -filter:v "minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=120'" "$@"

slomo.mp4: slomoi.mp4
	ffmpeg -y -i "$<" -filter:v "setpts=4.0*PTS" -r 30 "$@"

contrasted.mp4: slomo.mp4
	ffmpeg -y -i "$<" -filter:v "eq=contrast=2:brightness=0.1:gamma=1:gamma_r=1:gamma_g=1:gamma_b=1:gamma_weight=1" "$@"

slimmed.mp4: contrasted.mp4
	ffmpeg -y -i "$<" -ss 00:00:00 -t 00:00:20 -async 1 "$@"

clouds.mp4: slimmed.mp4
	ffmpeg -y -i "$<" -filter_complex \
		"[0]split[body][pre];[pre]trim=duration=5,format=yuva420p,fade=d=5:alpha=1,setpts=PTS+(10/TB)[jt];[body]trim=5,setpts=PTS-STARTPTS[main];[main][jt]overlay" "$@"

clouds.webm: clouds.mp4
	ffmpeg -y -i "$<" -vcodec libvpx -qmin 0 -qmax 50 -crf 10 -b:v 1M -an "$@"

.PHONY: clean
clean:
	rm -f cut.mp4 clouds.mp4 slomo.mp4 slomoi.mp4 cropped.mp4 desaturated.mp4 contrasted.mp4 slimmed.mp4 clouds.webm
