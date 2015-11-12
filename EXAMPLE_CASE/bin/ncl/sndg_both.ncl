load "$NCARG_LIB/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "/glade/p/ral/jnt/MMET/2009121712/bin/ncl/skewt_func.ncl"

title = getenv ("TITLE") + " "
theos = systemfunc("uname")
modl = getenv("MODEL") + " "
domain = getenv("DOMAIN")
;

begin

debug = 0
a1name = asciiread("arw1_nv_file.txt",-1,"string")
  arw1_file = addfile(a1name,"r")
a2name = asciiread("arw2_nv_file.txt",-1,"string")
  arw2_file = addfile(a2name,"r")

  names = getfilevarnames(arw1_file)  ; Get the variable names in the
  if (debug.eq.1) then
     print(names)                       ; GRIB file and print them out.
;
     do i = 0, dimsizes( names ) - 1
       print("Variable Name: " + names(i))
       dims = getfilevardims(arw1_file,names(i))
       sizes = filevardimsizes(arw1_file,names(i))
       print(dimsizes(sizes) + " Dimensions:")
       if(.not.any(ismissing(dims))) then
         do j = 0, dimsizes(dims) -1
           print( j + ") " + dims(j) + ": " + sizes(j))
         end do  
       end if
       atts = getfilevaratts(arw1_file,names(i))
       if(.not.any(ismissing(atts))) then
         do k = 0, dimsizes(atts) -1
           print(atts(k) + ": " +arw1_file->$names(i)$@$atts(k)$)
         end do
       end if
       delete(atts)
       delete(dims)
       delete(sizes)
       print("")
     end do
     smpl = arw1_file->lv_HYBL0(:)

     do i = 0, 38
       print(i)
       print(smpl(i))
     end do
  end if

  intm = arw1_file->TMP_GDS3_HYBL@initial_time
  fctm = arw1_file->TMP_GDS3_HYBL@forecast_time
  lat = arw1_file->g3_lat_1(:,:)
  lon = arw1_file->g3_lon_2(:,:)
  
;  print(lat)
;  print(lon)

; CT2007 soundings

;  slat = (/47.96, 40.82, 34.71, 44.11, 35.22, 41.57, 32.28, 42.73, 32.87, 25.69/)
;  slon = (/-124.53, -112.05, -120.55, -103.15, -101.75, -90.64, -90.14, -73.81, -80.03, -80.37/)
;  snam = (/"UIL", "SLC", "VBG", "UNR", "AMA", "DVN", "JAN", "ALB", "CHS", "MFL"/)
;  i_val = (/257, 182, 140, 205, 129, 182, 104, 202, 114, 55/)
;  j_val = (/70, 136, 72, 195, 200, 274, 280, 380, 350, 354/)

; WRFRR_VL soundings

;  slat = (/39.75, 31.93, 32.83, 30.12, 48.55, 44.48, 44.90, 42.68, 43.88, 46.87, 46.30, 51.27, 51.45, 53.97/)
;  slon = (/-104.87, -102.18, -117.12, -93.20, -93.38, -88.10, -84.72, -73.82, -70.25, -68.00, -76.00, -80.65, -90.20, -101.10/)
;  snam = (/"KDNR", "KMAF", "KNKX", "KLCH", "KINL", "KGRB", "KAPX", "KALB", "KGYX", "KCAR", "CWMW", "CYMO", "CWPL", "CYQD"/)
;  i_val = (/151, 85, 105, 70, 225, 193, 200, 196, 212, 240, 222, 257, 250, 270/)
;  j_val = (/160, 175, 70, 240, 229, 263, 282, 351, 369, 373, 330, 295, 245, 187/)

; AFWAref/RRTMG soundings

;  slat = (/47.95, 34.75, 36.61, 47.68, 39.75, 32.23, 44.08, 35.23, 41.61, 37.23, 32.31, 37.20, 42.70, 32.90 /)
;  slon = (/-124.55, -120.56, -116.01, -117.63, -104.87, -110.96, -103.21, -101.70, -90.58, -93.38, -90.08, -80.41, -73.83, -80.03 /)
;  snam = (/"KUIL", "KVBG", "KDRA", "KOTX", "KDNR", "KTUS", "KRAP", "KAMA", "KDVN", "KSGF", "KJAN", "KRNK", "KALB", "KCHS"/)
;  i_val = (/236, 135, 144, 227, 161, 108, 193, 127, 179, 145, 111, 157, 206, 126 /)
;  j_val = (/88, 88, 117, 122, 184, 144, 194, 202, 264, 251, 275, 327, 352, 336 /)

; Sfc Drag testing
;  snam = (/"KUIL", "KVBG", "KDRA", "KOTX", "KDNR", "KTUS", "KRAP", "KAMA", "KDVN", "KSGF", "KJAN", "KRNK", "KALB", "KCHS"/)
; d01
;  if(domain .eq. "d01") then
;    i_val = (/203,102,113,196,133,78,166,101,155,121,88,137,187,107/)
;    j_val = (/30,36,65,64,130,93,138,150,209,198,224,273,296,284/)
;  else if (domain .eq. "d02") then
; d02
;    i_val = (/609,307,338,587,400,234,498,302,465,362,263,410,562,320/)
;    j_val = (/91,107,194,193,391,279,415,451,626,595,672,819,887,853/)
;  else
;    print("A non-accounted domain was requested.")
;  end if
;  end if

; MMET soundings
  snam = (/"KUIL", "KVBG", "KDRA", "KOTX", "KDNR", "KTUS", "KRAP", "KAMA", "KDVN", "KSGF", "KJAN", "KRNK", "KALB", "KCHS"/)
  i_val = (/203,102,113,196,133,78,166,101,155,121,88,137,187,107/)
  j_val = (/30,36,65,64,130,93,138,150,209,198,224,273,296,284/)

  year = stringtointeger(getSubString(intm,6,9))
  mon  = stringtointeger(getSubString(intm,0,1))
  day  = stringtointeger(getSubString(intm,3,4))
  hour = stringtointeger(getSubString(intm,12,13))
  time = (/0.0/)
  time@units = "seconds since 1970-01-01 00:00:0.0"
  date = ut_inv_calendar(year,mon,day,hour,0,0,time@units, 0)
  fcst = (/date + stringtointeger(fctm)*3600/)
  fcst@units = "seconds since 1970-01-01 00:00:0.0"
  utc_date = ut_calendar(fcst, 0)
  year   = floattointeger(utc_date(:,0))    ; Convert to integer for
  month  = floattointeger(utc_date(:,1))    ; use in the sprinti function.
  day    = floattointeger(utc_date(:,2))
  hour   = floattointeger(utc_date(:,3))
  minute = floattointeger(utc_date(:,4))
  second = utc_date(:,5)
  date_str = "Valid " + sprinti("%0.2i/", month) + sprinti("%0.2i/",day) + \
             sprinti("%0.4i", year) + " " + sprinti("%0.2i:00 ", hour)  + \
             "UTC"
  print(date_str)
m=0
do while (m.le.13)
;
; read in ARW data and process
;
  atvar = arw1_file->TMP_GDS3_HYBL(:,i_val(m),j_val(m)) - 273.15
  atdvar= arw1_file->DPT_GDS3_HYBL(:,i_val(m),j_val(m)) - 273.15
  ahvar = arw1_file->HGT_GDS3_HYBL(:,i_val(m),j_val(m))
  apvar = arw1_file->PRES_GDS3_HYBL(:,i_val(m),j_val(m)) / 100
;  apvar = arw1_file->lv_HYBL_100(:)
  
;  print(atvar)
;  print(apvar)

  auvar = arw1_file->U_GRD_GDS3_HYBL(:,i_val(m),j_val(m)) * 1.9429 ; convert to knots
  avvar = arw1_file->V_GRD_GDS3_HYBL(:,i_val(m),j_val(m)) * 1.9429 ; convert to knots
  arot = arw1_file->g3_rot_3(i_val(m),j_val(m)) 

  auearth = sin(arot)*avvar + cos(arot)*auvar
  avearth = cos(arot)*avvar - sin(arot)*auvar

  auv2 = auearth * auearth
  avv2 = avearth * avearth
  awind = sqrt(auv2 + avv2) + 0.00001

  awspd = new ( dimsizes(apvar), "float", -999.)  ; wspd@_FillValue = -999.
;  print(awspd)
  awdir = new ( dimsizes(apvar), "float", -999.)  ; wdir@_FillValue = -999.
  aangleC = new ( dimsizes(apvar), "float", -999.)  ; angleC@_FillValue = -999.)

  ap = apvar(::-1)
;  print(ap)
  at = atvar(::-1)
  atd= atdvar(::-1)
  ah = ahvar(::-1)
  au = auearth(::-1)
  av = avearth(::-1)

  i = 0
  do i = 0, dimsizes( ap ) - 1
    if (( av(i) .eq. 0 ) .or. ( au(i) .eq. 0)) then
      if ( av(i) .eq. 0) then
        awspd(i) = au(i)
        if ( au(i) .gt. 0 ) then
          awdir(i) = 270
        else
          awdir(i) = 90
        end if
      else
        awspd(i) = av(i)
        if ( av(i) .gt. 0 ) then
          awdir(i) = 180
        else
          awdir(i) = 0
        end if
      end if
    else
      aangleC(i) = (atan(av(i)/au(i)))  
      awspd(i) = (av(i) / (sin(aangleC(i))))
      if ( au(i) .gt. 0 ) then
        awdir(i) = 360 - (90 + (aangleC(i) * 57.2957795)) ; degrees
      else
        awdir(i) = 360 - (180 + (aangleC(i) * 57.2957795))
      end if
    end if
  end do

;
; read in ARW2 data and process
;
  ntvar = arw2_file->TMP_GDS3_HYBL(:,i_val(m),j_val(m)) - 273.15
  ntdvar= arw2_file->DPT_GDS3_HYBL(:,i_val(m),j_val(m)) - 273.15
  nhvar = arw2_file->HGT_GDS3_HYBL(:,i_val(m),j_val(m))
;  npvar = arw2_file->lv_HYBL0(:)
  npvar = arw2_file->PRES_GDS3_HYBL(:,i_val(m),j_val(m)) / 100
  nuvar = arw2_file->U_GRD_GDS3_HYBL(:,i_val(m),j_val(m)) * 1.9429 ; convert to knots
  nvvar = arw2_file->V_GRD_GDS3_HYBL(:,i_val(m),j_val(m)) * 1.9429 ; convert to knots
  nrot = arw2_file->g3_rot_3(i_val(m),j_val(m))

  nuearth = sin(nrot)*nvvar + cos(nrot)*nuvar
  nvearth = cos(nrot)*nvvar - sin(nrot)*nuvar

  nuv2 = nuearth * nuearth
  nvv2 = nvearth * nvearth
  nwind = sqrt(nuv2 + nvv2) + 0.00001

  nwspd = new ( dimsizes(npvar), "float", -999.)  ; wspd@_FillValue = -999.
  nwdir = new ( dimsizes(npvar), "float", -999.)  ; wdir@_FillValue = -999.
  nangleC = new ( dimsizes(npvar), "float", -999.)  ; angleC@_FillValue = -999.)

  np = npvar(::-1)
  nt = ntvar(::-1)
  ntd= ntdvar(::-1)
  nh = nhvar(::-1)
  nu = nuearth(::-1)
  nv = nvearth(::-1)

  i = 0
  do i = 0, dimsizes( np ) - 1
    if (( nv(i) .eq. 0 ) .or. ( nu(i) .eq. 0)) then
      if ( nv(i) .eq. 0) then
        nwspd(i) = nu(i)
        if ( nu(i) .gt. 0 ) then
          nwdir(i) = 270
        else
          nwdir(i) = 90
        end if
      else
        nwspd(i) = nv(i)
        if ( nv(i) .gt. 0 ) then
          nwdir(i) = 180
        else
          nwdir(i) = 0
        end if
      end if
    else
      nangleC(i) = (atan(nv(i)/nu(i)))  
      nwspd(i) = (nv(i) / (sin(nangleC(i))))
      if ( nu(i) .gt. 0 ) then
        nwdir(i) = 360 - (90 + (nangleC(i) * 57.2957795)) ; degrees
      else
        nwdir(i) = 360 - (180 + (nangleC(i) * 57.2957795))
      end if
    end if
  end do

;*************************
; create plot
;*************************
;
; Create an application object.
;
appid = create "mdss" appClass defaultapp
    "appUsrDir" : "./"
    "appDefaultParent" : True
end create
;
; Set only one of the following three params to 1, depending on the type
; of output desired (NCGM=metacode file, X11=screen, PS=PostScript file)
;
    NCGM=1
    X11=0
    PS=0
;
    if (NCGM .eq. 1) then
;
; Create an ncgmWorkstation object.
;
        wid = create "mdssWork" ncgmWorkstationClass defaultapp
           "wkMetaName" : "./skewt_" +snam(m)+ ".ncgm"
        end create
    else
      if (X11 .eq. 1) then
;
; Create an XWorkstation object.
;
        wid = create "mdssWork" xWorkstationClass defaultapp
            "wkPause" : True
        end create
      else
        if (PS .eq. 1) then
;
; Create a PSWorkstation object.
;
          wid = create "mdssWork" psWorkstationClass defaultapp
           "wkPSFileName" : "./skewt.ps"
          end create
        end if
      end if
    end if
;  wks  = gsn_open_wks ("ps", "skewt")

; --- Create background skew-T; plot sounding ---------------------
  skewtOpts                 = True
  skewtOpts@DrawColAreaFill = True    ; default is False
  skewtOpts@tiMainString    = snam(m) +" Sounding [AFWAref (blue) & RRTMG (magenta)]"

  skewt_bkgd = skewT_BackGround(wid,skewtOpts)
  draw (skewt_bkgd)

  dataOpts                  = True     ; options describing data and ploting
  dataOpts@PrintZ           = False
  dataOpts@ThermoInfo       = False    ; print thermodynamic info

;
; ARW Sounding
;
  dataOpts@colTemperature = "blue"
  dataOpts@colDewPt       = dataOpts@colTemperature
  dataOpts@colWindP       = dataOpts@colTemperature
  dataOpts@linePatternDewPt = 2
  dataOpts@xpWind      = 45.      ; new location for winds [default 45]
  skewt_data = skewT_PlotData(wid,skewt_bkgd,ap,at,atd,ah,awspd,awdir,dataOpts)
  draw (skewt_data)

;
; ARW2 Sounding
;
  dataOpts@colTemperature = "magenta"
  dataOpts@colDewPt       = dataOpts@colTemperature
  dataOpts@colWindP       = dataOpts@colTemperature
  dataOpts@xpWind      = 40.      ; new location for winds [default 45]

  skewt_data = skewT_PlotData(wid,skewt_bkgd,np,nt,ntd,nh,nwspd,nwdir,dataOpts)

  txid = create "TextItems" textItemClass wid
    "txFuncCode" : "~"
    "txString" : title+intm+" "+fctm+" hr fcst"
    "txFont" : 22
    "txFontHeightF" : 0.015
    "txFontColor" : "red"
  end create
  txid2 = create "TextItems" textItemClass wid
    "txFuncCode" : "~"
    "txString" : date_str
    "txFont" : 22
    "txFontHeightF" : 0.015
    "txFontColor" : "red"
  end create

  ianno = NhlAddAnnotation(skewt_data,txid)
  setvalues ianno
    "amParallelPosF":    -0.35
    "amOrthogonalPosF":  0.57
  end setvalues
  ianno2 = NhlAddAnnotation(skewt_data,txid2)
  setvalues ianno2
    "amParallelPosF":    0.35
    "amOrthogonalPosF":  0.57
  end setvalues

  draw (skewt_data)
  frame(wid)

m = m+1
end do
;
end
;
