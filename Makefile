IMG_NAME=hr.img

out:
	. ./settings.sh; make_out.sh
in:
	. ./settings.sh; make_in.sh
sync:
	# ???

img:
	gmt -j -v -m "SLAZAV-HR" -f 779,2 -o ${IMG_NAME} OUT/*.img /usr/share/mapsoft/slazav.typ
	mv -f ${IMG_NAME} /home/sla/CH/data/maps/
	sed -e "/${IMG_NAME}/s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/$(date +%F)/"\
	  -i /home/sla/CH/data/maps/index.m4i

index: index_fan index_pam index_zab index_saj index_tsh index_kav index_nep index_put\
  index_ura index_sun index_chi

index_kav:
	. bin/map_update_index.sh 420000x210000+8080000+4685000 kav
index_fan:
	. bin/map_update_index.sh 320000x200000+12360000+4240000 fan
index_pam:
	. bin/map_update_index.sh 250000x350000+13180000+4050000 pam
index_tsh:
	. bin/map_update_index.sh 150000x130000+14240000+4610000 tsh
index_zab:
	. bin/map_update_index.sh 420000x320000+19310000+6020000 zab
index_saj:
	. bin/map_update_index.sh 390000x480000+17260000+5560000 saj
index_nep:
	. bin/map_update_index.sh 700000x350000+14240000+3120000 nep
index_put:
	. bin/map_update_index.sh 90000x160000+16415000+7615000 put
index_ura:
	. bin/map_update_index.sh 120000x100000+10580000+7160000 ura
index_sun:
	. bin/map_update_index.sh 300000x200000+24380000+6835000 sun

index_chi:
	. bin/map_update_index.sh 180000x280000+48650000-4980000 chi


update_passes:
	map_wp_upd_nom vmap/*.vmap
