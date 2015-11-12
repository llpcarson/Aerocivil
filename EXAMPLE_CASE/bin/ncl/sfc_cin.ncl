;
load "$NCARG_LIB/ncarg/nclscripts/csm/contributed.ncl"
theos = systemfunc("uname")
modl = getenv("MODEL") + " "
title = getenv ("TITLE") + " "
point1_str = getenv ("POINT1")
point2_str = getenv ("POINT2")
nxin_str = getenv ("NXIN")
nyin_str = getenv ("NYIN")
;
function gen_colormap( )
begin
        ;This procedure explicitly sets the red, green, and blue
        ;intensities for each element in a colormap array.
 
        ; Set the color map
        ; Entry 0 is the background color.
 
        ; Entry 1 is the foreground color.
        ; The continental outlines in the map object use this color
        ; as a default.
        return( (/ (/0.000,0.000,0.000/), \
                (/1.000,1.000,1.000/), \
                (/.150,.150,.150/), \
                (/.200,.200,.200/), \
                (/.300,.300,.300/), \
                (/.400,.400,.400/), \
                (/.500,.500,.500/), \
                (/.600,.600,.600/), \
                (/.700,.700,.700/), \
                (/.800,.800,.800/), \
                (/.850,.850,.850/), \
                (/.930,.857,1.000/), \
                (/.860,.714,1.000/), \
                (/.800,.571,1.000/), \
                (/.750,.428,1.000/), \
                (/.700,.285,1.000/), \
                (/.650,.142,1.000/), \
                (/.600,.000,1.000/), \
                (/.550,.000,.800/), \
                (/.500,.000,.750/), \
                (/.450,.000,.700/), \
                (/.400,.300,.650/), \
                (/.350,.450,.600/), \
                (/.200,.600,.650/), \
                (/.100,.750,.750/), \
                (/.000,.700,1.000/), \
                (/.000,.700,.400/), \
                (/.000,.900,.300/), \
                (/.000,1.000,.000/), \
                (/.500,.900,.000/), \
                (/.500,.800,.000/), \
                (/.500,.700,.000/), \
                (/.500,.600,.000/), \
                (/.500,.500,.000/), \
                (/.550,.450,.000/), \
                (/.700,.300,.000/), \
                (/.750,.250,.000/), \
                (/.800,.200,.000/), \
                (/.850,.150,.000/), \
                (/.900,.100,.000/), \
                (/.950,.050,.000/), \
                (/1.000,.000,.000/), \
                (/1.000,.600,.000/), \
                (/1.000,.800,.000/), \
                (/1.000,1.000,.000/) /) )
end
;
begin

fname = asciiread("arw1_file.txt",-1,"string")
  debug = 0 
  grb_file = addfile(fname,"r")
  names = getfilevarnames(grb_file)  ; Get the variable names in the

if (debug.eq.1) then
  print(names)                       ; GRIB file and print them out.
;
  do i = 0, dimsizes( names ) - 1
    print("Variable Name: " + names(i))
    dims = getfilevardims(grb_file,names(i))
    sizes = filevardimsizes(grb_file,names(i))
    print(dimsizes(sizes) + " Dimensions:")
    if(.not.any(ismissing(dims))) then
      do j = 0, dimsizes(dims) -1
        print( j + ") " + dims(j) + ": " + sizes(j))
      end do  
    end if
    atts = getfilevaratts(grb_file,names(i))
    if(.not.any(ismissing(atts))) then
      do k = 0, dimsizes(atts) -1
        print(atts(k) + ": " +grb_file->$names(i)$@$atts(k)$)
      end do
    end if
    delete(atts)
    delete(dims)
    delete(sizes)
    print("")
  end do
end if
;
if (modl .eq. "WRF-RR RUC-13 " .or. modl .eq. "WRFRUC RUC-13 ") then
  intm = grb_file->T_130_HTGL@initial_time
  fctm = grb_file->T_130_HTGL@forecast_time
  lat = grb_file->gridlat_130(:,:)
  lon = grb_file->gridlon_130(:,:)
  latin1 = grb_file->gridlon_130@Latin1
  latin2 = grb_file->gridlon_130@Latin2
  lov = grb_file->gridlon_130@Lov

  tvar = grb_file->CIN_130_SFC(:,:)
else
  intm = grb_file->TMP_GDS0_HTGL@initial_time
  fctm = grb_file->TMP_GDS0_HTGL@forecast_time
  lat = grb_file->g0_lat_0(:)
  lon = grb_file->g0_lon_1(:)
  lat1 = grb_file->g0_lon_1@La1
  lat2 = grb_file->g0_lon_1@La2
  lon1 = grb_file->g0_lon_1@Lo1
  lon2 = grb_file->g0_lon_1@Lo2

  tvar = grb_file->CIN_GDS0_SFC(:,:)
end if

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
             sprinti("%0.4i", year) + " " + sprinti("%0.2i:00 ", hour) + \
             "UTC"

;lrb if (modl .eq. "WRF-RR ARW ") then
;lrb   lov = -95.0
;lrb   LcLon = -139.9698
;lrb   LcLat = 54.20501
;lrb   RcLon = -68.98730
;lrb   RcLat = 17.26922
;lrb else
  point1 = stringtoint(point1_str)
  point2 = stringtoint(point2_str)
  nxin   = stringtoint(nxin_str)
  nyin   = stringtoint(nyin_str)

  LcLon = lon(point2)
  LcLat = lat(point2)
  RcLon = lon(0)
  RcLat = lat(0)
;lrb end if
;
print(date_str)
print("CIn")
print(min(tvar))
print(max(tvar))

  nx = nxin 
  ny = nyin 
  xdim = nx - 1
  ydim = ny - 1
  rnx = 1.*xdim
  rny = 1.*ydim
  if (rny .ge. rnx) then
    vpheight = .96
    vpy = 1.-((1.-vpheight)/2.)
    vpwidth = (vpheight/rny)*rnx
    vpx = (1.-((vpheight/rny)*rnx))/2.
  else
    vpwidth = .96
    vpx = (1.-vpwidth)/2.
    vpheight = (vpwidth/rnx)*rny
    vpy = 1.-((1.-((vpwidth/rnx)*rny))/2.)
  end if
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
           "wkMetaName" : "./sfc_cin.ncgm"
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
           "wkPSFileName" : "./ruc.ps"
          end create
        end if
      end if
    end if
;
; Assign the colormap to the workstation.
setvalues wid
   "wkColorMap" : gen_colormap()
end setvalues
;
; Increase workspace memory
setvalues NhlGetWorkspaceObjectId()
   "wsMaximumSize": 247108864
end setvalues
;
mpid = create "mapplot" mapPlotClass wid 
;
  "mpProjection" : "Mercator"
;
  "mpLimitMode" : "Corners"    ; Limit the map view.
  "mpLeftCornerLonF" : LcLon
  "mpLeftCornerLatF" : LcLat
  "mpRightCornerLonF" : RcLon
  "mpRightCornerLatF" : RcLat
  "mpOutlineBoundarySets" : "AllBoundaries"
  "mpGridAndLimbOn" : False
  "mpGeophysicalLineColor" : "background"
  "vpXF"      : vpx        ; set viewport
  "vpYF"      : vpy
  "vpWidthF"  : vpwidth 
  "vpHeightF" : vpheight
;
end create
;
; Create a ScalarField object.
;
tfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : tvar
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
end create
;
;if ( theos .ne. "AIX") then
;  modl = "WRF-RR "
;else
;  modl = "DWFE ARW "
;end if

;
;
;fillindices = ispan(17,43,1) ; Create array with indices to the colormap
;                           ; (skips first two colormap entries which
;                           ; are the background and foreground colors)
;
; Create a ContourPlot object.
;
; Relative Humidity
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  tfield
    "cnFillColors" : (/ 1,41,42,43,33,31,28,26,24,22,20,17,15,13,11,7,10,1 /)
;    "cnFillColors" : (/ 1,10,7,11,13,15,17,20,22,24,26,28,31,33,43,42,41,1 /)
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" : -400 
    "cnMaxLevelValF" : 0
    "cnLevelSpacingF" : 25 
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnLineLabelsOn" : False
    "cnInfoLabelOn" : False
    "cnRasterModeOn" : True
    "pmTickMarkDisplayMode" : "NoCreate"
    "pmLabelBarDisplayMode" : "ALWAYS"
    "pmLabelBarHeightF" : .05
    "pmLabelBarWidthF" : 0.9
    "pmLabelBarSide" : "bottom"
    "pmLabelBarOrthogonalPosF" : 0.0
    "tiMainString" : "Convective Inhibition (J/kg)"
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 43
    "tiMainOffsetYF" : -0.013
    "lbOrientation" : "horizontal"
    "lbTitleFont" : 22 
    "lbPerimOn" : False
    "lbBoxLinesOn" : 0
;    "lbLabelStride" : 2
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
txid = create "TextItems" textItemClass wid
  "txFuncCode" : "~"
  "txString" : title+intm+" "+fctm+" hr fcst"
  "txFont" : 22
  "txFontHeightF" : 0.015
  "txFontColor" : 1
end create
;
txid2 = create "TextItems" textItemClass wid
  "txFuncCode" : "~"
  "txString" : date_str
  "txFont" : 22
  "txFontHeightF" : 0.015
  "txFontColor" : 1
end create
ianno = NhlAddAnnotation(cnid,txid)
setvalues ianno
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomleft"
  "amParallelPosF":    0.0
  "amOrthogonalPosF":  0.018
end setvalues
ianno2 = NhlAddAnnotation(cnid,txid2)
setvalues ianno2
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomright"
  "amParallelPosF":    1.0
  "amOrthogonalPosF":  0.018
end setvalues
;
;
; Draw map of Sfc RelHum, Wind
;
draw(cnid)
draw(mpid)
frame(wid)
;
end
;
