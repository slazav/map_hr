IMG_NAME=hr.img

RNG_FAN=150000x150000+12350000+4250000
RNG_PAM=450000x350000+13000000+4050000
RNG_ZAB=300000x200000+19300000+6020000

out:
	. ./settings.sh; make_out.sh
in:
	. ./settings.sh; make_in.sh
sync:
	# ???

img:
	gmt -j -v -m "SLAZAV-1" -o ${IMG_NAME} OUT/*.img /usr/share/mapsoft/slazav.typ
	mv -f ${IMG_NAME} /home/sla/CH/data/maps/
	sed -e "/${IMG_NAME}/s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/$(date +%F)/"\
	  -i /home/sla/CH/data/maps/index.m4i

index:
	. ./settings.sh; map_update_index.sh 600000x400000+7085000+5970000


update_passes:
	map_wp_upd_nom vmap/*.vmap