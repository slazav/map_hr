#!/bin/sh -eu

OUT_DIR=/home/sla/map_hr/OUT
VMAP_DIR=/home/sla/map_hr/vmap
. mapsoft_crd.sh

if [ "$#" != 2 ]; then
  echo "use: $0 <geom> <base>"
  exit 1
fi

geom=$1
base=$2

jpeg_scale=0.2
jpg=all_$base.jpg
htm=all_$base.htm
xml=all_$base.xml
img=all_$base.img
txt=all_$base.txt

cd "$OUT_DIR"

# calculate map list
maps=''
imgs=''
upd=''

pwd
for n in $(geom2nom "$geom" 100000); do
  n1=$(echo $VMAP_DIR/$n*.vmap)
  [ -f "$n1" ] || continue
  n=$(basename $n1 .vmap)

  [ "$n.png" -ot "$htm" ] || upd=1;
  [ ! -f "$n.map" ] || maps="$maps $n.map"
  [ ! -f "$n.img" ] || imgs="$imgs $n.img"
done
[ "$txt" -ot "$htm" -a "$txt" -ot "$jpg" ] || upd=1;

echo "MAPS: $maps"

if [ -z "$upd" ]; then echo "no need to update $base index"; exit 0; fi

# make xml with all small jpeg maps; make index image and htm
mapsoft_convert $maps *.plt --rescale_maps=$jpeg_scale -o "$xml"
sed -i -e 's/.png/.jpg/g' "$xml"
mapsoft_convert "$xml" --geom "$geom" -o "$jpg"\
  --map_show_brd --dpi=6 --rscale=100000 --htm="tmp.htm"

cat > "$htm" <<-EOF
	<html>
        <head>
	  <title>$name</title>
	  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=koi8-r">
	</head>
        <body>
	EOF
[ ! -f "$txt" ] || cat "$txt" >> $htm
sed -e '
  /^<area/{
    s/"\([^"]*\)\.jpg" alt="" title=""/"\1.htm" alt="\1" title="\1"/
    s/"\([^"]*\)\.jpg"/"\1.htm"/
    s/ href="..\/skl_map\/[^"]*"//
    /<\/html>/d
    /<html>/d
  }' tmp.htm >> "$htm"

for i in $(echo $maps | tr ' ' '\n' | sort); do
  n=${i%.map}
  t=$(stat -c %y $n.png | sed 's/ .*//')
  cat >> "$htm" <<EOF
  <li><a href="$n.htm">$n</a> --
      <a href="$n.png">[PNG]</a>
      <a href="$n.map">[MAP]</a>
      <a href="$n.mp.zip">[MP.ZIP]</a>
      <font color="grey">$t</font>
EOF
done
cat >> "$htm" <<EOF
  </ul>
  <p><a href="$img">Полная карта для Garmin, IMG</a>
  <p><a type="text/plain" href="$xml">Привязка всех карт для mapsoft</a>
  <p><a href="http://slazav-news.livejournal.com/550874.html">
      Запись (ЖЖ) для сбора замечаний и исправлений</a>
  <p><a href="https://github.com/slazav/map_hr">
      Исходники карт на github (самодельный векторный формат)</a>
  <p>Последнее обновление: $(date +"%F %X")

  <div align="right">
  <!--Rating@Mail.ru counter-->
  <script language="javascript" type="text/javascript"><!--
  d=document;var a='';a+=';r='+escape(d.referrer);js=10;//--></script>
  <script language="javascript1.1" type="text/javascript"><!--
  a+=';j='+navigator.javaEnabled();js=11;//--></script>
  <script language="javascript1.2" type="text/javascript"><!--
  s=screen;a+=';s='+s.width+'*'+s.height;
  a+=';d='+(s.colorDepth?s.colorDepth:s.pixelDepth);js=12;//--></script>
  <script language="javascript1.3" type="text/javascript"><!--
  js=13;//--></script><script language="javascript" type="text/javascript"><!--
  d.write('<a href="http://top.mail.ru/jump?from=74208" target="_top">'+
  '<img src="http://d1.c2.b1.a0.top.mail.ru/counter?id=74208;t=52;js='+js+
  a+';rand='+Math.random()+'" alt=".......@Mail.ru" border="0" '+
  'height="31" width="88"><\/a>');if(11<js)d.write('<'+'!-- ');//--></script>
  <noscript><a target="_top" href="http://top.mail.ru/jump?from=74208">
  <img src="http://d1.c2.b1.a0.top.mail.ru/counter?js=na;id=74208;t=52".
  height="31" width="88" border="0" alt=".......@Mail.ru"></a></noscript>
  <script language="javascript" type="text/javascript"><!--
  if(11<js)d.write('--'+'>');//--></script>
  <!--// Rating@Mail.ru counter-->
  </div>

</body>
</html>
EOF



# make more useful xml
mapsoft_convert $maps -o "$xml"

# make img file
gmt -j -v -m "slazav-$base" -o $img $imgs /usr/share/mapsoft/slazav.typ

cd -
