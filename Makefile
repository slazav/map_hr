IMG_NAME=hr.img

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

index: index_fan index_pam index_zab index_saj index_tsh index_kav

index_kav:
	. bin/map_update_index.sh 500000x200000+8000000+4680000 kav
index_fan:
	. bin/map_update_index.sh 150000x160000+12360000+4240000 fan
index_pam:
	. bin/map_update_index.sh 250000x350000+13180000+4050000 pam
index_tsh:
	. bin/map_update_index.sh 150000x130000+14240000+4610000 tsh
index_zab:
	. bin/map_update_index.sh 420000x320000+19310000+6020000 zab
index_saj:
	. bin/map_update_index.sh 390000x430000+17260000+5610000 saj


update_passes:
	map_wp_upd_nom vmap/*.vmap
