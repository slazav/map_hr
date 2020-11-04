###############################
# 2020-10-31, new rendering system

VDIR  = vmap
ODIR  = OUT
TDIR = tiles
DBDIR = mapdb
CFDIR = conf
DFDIR = diff

MS2MAPDB = ms2mapdb
#VMAP = $(VDIR)/j42-043.vmap
#VMAP = $(wildcard $(VDIR)/j42-*.vmap)
VMAP = $(wildcard $(VDIR)/*.vmap)

# What do we want to generate
PNG = $(patsubst $(VDIR)/%.vmap, $(ODIR)/%.png,     $(VMAP))
JPG = $(patsubst $(VDIR)/%.vmap, $(ODIR)/%.jpg,     $(VMAP))
MPZ = $(patsubst $(VDIR)/%.vmap, $(ODIR)/%.mp.zip,  $(VMAP))
IMG = $(patsubst $(VDIR)/%.vmap, $(ODIR)/%.img,     $(VMAP))
MDB = $(patsubst $(VDIR)/%.vmap, $(DBDIR)/%,        $(VMAP))

all: $(PNG) $(MPZ) $(IMG)

# create mapdb from vmap
$(DBDIR)/%: $(VDIR)/%.vmap
	$(MS2MAPDB) delete $@
	$(MS2MAPDB) create $@
	$(MS2MAPDB) import_vmap $@ $< --config $(CFDIR)/import_vmap.cfg

# generate colormap from a single map 
CMAP = $(ODIR)/cmap.png
$(CMAP): $(DBDIR)/j42-040.3x3
	name=`basename $<`;\
	$(MS2MAPDB) render $<\
	  --out tmp_cmap.png --config $(CFDIR)/render.cfg\
	  --define "{\"nom_name\":\"$$name\", \"hr\":\"1\"}"\
	  --cmap_color 255 --cmap_save $@ --cmap_add 0\
	  --png_format pal;\
	rm -f tmp_cmap.png

# generate PNG image + map, make diff files
$(ODIR)/%.png: $(DBDIR)/% $(CMAP) $(CFDIR)/render.cfg
	name=`basename $<`;\
	date=`date +"%Y-%m-%d"`;\
	[ -s "$@" ] && convert $@ -scale 50% "$(DFDIR)/$${name}_o.png" ||:;\
	\
	$(MS2MAPDB) render $< --out $@ --config $(CFDIR)/render.cfg\
	 --define "{\"nom_name\":\"$$name\", \"hr\":\"1\"}"\
	 --mkref nom --name $$name --dpi 200 --margins 10 --top_margin 30\
	 --title "$$name   /$$date/" --title_size 20\
	 --cmap_load $(CMAP) --png_format pal --map $(ODIR)/$$name.map;\
	\
	convert $@  -scale 50% "$(DFDIR)/$${name}_n.png";\
	compare -matte "$(DFDIR)/$${name}_o.png" "$(DFDIR)/$${name}_n.png"\
	  "PNG8:$(DFDIR)/$${name}_d.png" ||:

# generate MP. ID should be unique, 8 decimal digits
$(ODIR)/%.mp: $(DBDIR)/% $(CFDIR)/export_mp.cfg
	name=`basename $<`;\
	id=`( echo "ibase=16"; echo Makefile | md5sum | head -c6 | tr a-z A-Z; echo ) | bc`;\
	ms2mapdb export_mp $< $@ --name "$$name" --id "$$id"

# generate IMG
$(ODIR)/%.img: $(ODIR)/%.mp
	cgpsmapper-static "$<" -o "$@"

# generate mp.zip
$(ODIR)/%.mp.zip: $(ODIR)/%.mp
	zip -j "$@" "$<"

# generate JPG (20% size)
$(ODIR)/%.jpg: $(ODIR)/%.png
	pngtopnm "$<" | pnmscale 0.2 | cjpeg -quality 50 > "$@"

# generate HTML
$(ODIR)/%.htm: $(ODIR)/%.png  $(ODIR)/%.img  $(ODIR)/%.mp.zip $(ODIR)/%.jpg
	name=`basename $< .png`;\
	date=`date +"%Y-%m-%d"`;\
	sed "s|((NAME))|$$name|g;s|((DATE))|$$date|g" $(CFDIR)/map.htm > $@

##################################################

# Generate tiles.
# - process all mapdb folders newer then tstamp in tiles/
# - render with --add switch: add information to existing tiles
# - render with --tmap_scale 1: rescale larger tiles to 
# - do separately for zoom 9..12 and 0..8

# 1st timestamp depends on configuration files.
# It's updated when configuration changes and tiles should be
# recreated from scratch.
TSTAMP1=$(TDIR)/tstamp1
$(TSTAMP1): $(CFDIR)/render.cfg $(CFDIR)/border.gpx $(CMAP)
	rm -f $(TDIR)/*.png $(TSTAMP2)
	touch $(TSTAMP1)

# 2nd timestamp is updated when tiles are updated.
# In normal situation only maps which are newer then tstamp2
# are rendered.
TSTAMP2=$(TDIR)/tstamp2
.PHONY: tiles
tiles: $(MDB) $(TSTAMP1)
	for n in $(MDB); do \
	[ "$$n/objects.db" -nt  "$(TSTAMP2)" ] || continue;\
	name=`basename $$n .png`;\
	$(MS2MAPDB) render $$n --config $(CFDIR)/render.cfg\
	  --define "{\"nom_name\":\"$$name\", \"hr\":\"1\", \"border_style\":\"none\"}"\
	  --tmap --add --out "tiles/{x}-{y}-{z}.png" --zmin 7 --zmax 13\
	  --bgcolor 0 --png_format pal --cmap_load $(CMAP)\
	  --border_file $(CFDIR)/border.gpx\
	  --tmap_scale 1;\
	$(MS2MAPDB) render $$n --config $(CFDIR)/render.cfg\
	  --define "{\"nom_name\":\"$$name\", \"hr\":\"1\", \"border_style\":\"none\"}"\
	  --tmap --add --out "tiles/{x}-{y}-{z}.png" --zmin 0 --zmax 6\
	  --bgcolor 0 --png_format pal --cmap_load $(CMAP)\
	  --border_file $(CFDIR)/border.gpx\
	  --tmap_scale 1;\
	done
	touch $(TSTAMP2)

##################################################
# old Makefile

in:
	. ./settings.sh; make_in.sh

IMG_NAME=hr.img
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

