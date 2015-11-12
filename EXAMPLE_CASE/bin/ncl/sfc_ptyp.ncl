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
        return( (/ (/.000,.000,.000/), \
                (/1.000,1.000,1.000/), \
                (/0.700,0.700,0.700/), \
                (/.000,.000,1.000/), \
                (/0.500,.500,1.000/), \
                (/1.000,.000,1.000/), \
                (/0.750,.250,.750/), \
                (/.500,.500,.500/), \
                (/.250,.250,.250/), \
                (/.000,1.000,.000/), \
                (/.142,.853,.000/), \
                (/.285,.711,.000/), \
                (/.427,.569,.000/), \
                (/.569,.427,.000/), \
                (/.711,.285,.000/), \
                (/.853,.142,.000/), \                
                (/1.000,.000,.000/), \
                (/1.000,.800,.000 /) /) )
end
;
begin

fname = asciiread("arw1_file.txt",-1,"string") 
  grb_file = addfile(fname,"r")
;
if (modl .eq. "WRF-RR RUC-13 " .or. modl .eq. "WRFRUC RUC-13 ") then
  intm = grb_file->T_130_HTGL@initial_time
  fctm = grb_file->T_130_HTGL@forecast_time
  lat = grb_file->gridlat_130(:,:)
  lon = grb_file->gridlon_130(:,:)
  latin1 = grb_file->gridlon_130@Latin1
  latin2 = grb_file->gridlon_130@Latin2
  lov = grb_file->gridlon_130@Lov
  snow = grb_file->CSNOW_130_SFC(:,:) * 1 
  icep = grb_file->CICEP_130_SFC(:,:) * 2 
  frzr = grb_file->CFRZR_130_SFC(:,:) * 4
  rain = grb_file->CRAIN_130_SFC(:,:) * 8
  ptyp = snow + icep + frzr + rain
else
  intm = grb_file->TMP_GDS0_HTGL@initial_time
  fctm = grb_file->TMP_GDS0_HTGL@forecast_time
  lat = grb_file->g0_lat_0(:)
  lon = grb_file->g0_lon_1(:)
  lat1 = grb_file->g0_lon_1@La1
  lat2 = grb_file->g0_lon_1@La2
  lon1 = grb_file->g0_lon_1@Lo1
  lon2 = grb_file->g0_lon_1@Lo2
  snow = grb_file->CSNOW_GDS0_SFC(:,:) * 1 
  icep = grb_file->CICEPL_GDS0_SFC(:,:) * 2 
  frzr = grb_file->CFRZR_GDS0_SFC(:,:) * 4
  rain = grb_file->CRAIN_GDS0_SFC(:,:) * 8
  ptyp = snow + icep + frzr + rain
end if
  if (fctm .eq. 0) then       ; blank map for 00-h
    ptyp = 0
    ptyp(1,1) = 1
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

     
print("snow")
print(min(snow))
print(max(snow))
print("icepellets")
print(min(icep))
print(max(icep))
print("freezing rain")
print(min(frzr))
print(max(frzr))
print("rain")
print(min(rain))
print(max(rain))


  point1 = stringtoint(point1_str)
  point2 = stringtoint(point2_str)
  nxin   = stringtoint(nxin_str)
  nyin   = stringtoint(nyin_str)

  LcLon = lon(point2)
  LcLat = lat(point2)
  RcLon = lon(0)
  RcLat = lat(0)

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
appid = create "wrfsi" appClass defaultapp
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
        wid = create "wrfsiWork" ncgmWorkstationClass defaultapp
           "wkMetaName" : "./sfc_ptyp.ncgm"
        end create
    else
      if (X11 .eq. 1) then
;
; Create an XWorkstation object.
;
        wid = create "wrfsiWork" xWorkstationClass defaultapp
            "wkPause" : True
        end create
      else
        if (PS .eq. 1) then
;
; Create a PSWorkstation object.
;
          wid = create "wrfsiWork" psWorkstationClass defaultapp
           "wkPSFileName" : "./sfc_ptyp.ps"
          end create
        end if
      end if
    end if
;
; Assign the colormap to the workstation.
setvalues wid
; Generate a colormap.
   "wkColorMap" : gen_colormap()
end setvalues
; Increase workspace memory
setvalues NhlGetWorkspaceObjectId()
   "wsMaximumSize": 33554432
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
;  "mpPerimOn" : True 
  "mpPerimLineThicknessF" : 1.5
  "vpXF"      : vpx        ; set viewport
  "vpYF"      : vpy
  "vpWidthF"  : vpwidth
  "vpHeightF" : vpheight
;
end create
;
; Create a ScalarField object.
;
varfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : ptyp
    "sfXCStartV" : 0 
    "sfYCStartV" : 0 
    "sfXCEndV" : ydim 
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
end create
;
minlv = 0 
maxlv = 8 
levsp = 1
;
; Create a ContourPlot object.
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  varfield
    "cnFillColors" : (/ 2,1,3,2,5,2,2,2,9 /)
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" : minlv 
    "cnMaxLevelValF" : maxlv
    "cnLevelSpacingF" : levsp 
    "cnRasterModeOn" : True
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnLineLabelsOn" : False
    "cnInfoLabelOn" : False
    "pmTickMarkDisplayMode" : "NoCreate"
    "tiMainString" : "Precip Type"
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 17 
    "tiMainOffsetYF" : -0.013
    "vpXF"      : vpx ; Viewport settings
    "vpYF"      : vpy
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
;
end create
;
lgid = create "Legend" legendClass wid
    "lgAutoManage" : False
    "lgOrientation" : "Horizontal"
    "lgItemCount" : 4
    "lgLineColors" : (/ 2,3,5,9 /)
    "lgLabelStrings" : (/"SNOW","ICE PELLETS","FREEZING RAIN","RAIN"/)
    "lgLabelFont" : 4
    "lgMonoLineLabelFontColor" : True
    "lgLabelFontHeightF" : 0.004
    "lgLabelOffsetF" : 0.03
    "lgLineThicknessF" : 4.0
    "lgMonoDashIndex" : True
    "vpXF"      : 0.02
    "vpYF"	: vpy - vpheight
    "vpWidthF"	: vpwidth
    "vpHeightF" : 0.03
end create
;
lbid = create "LabelBar" labelBarClass wid
    "lbOrientation" : "Horizontal"
    "lbAutoManage" : False
    "lbLabelFont" : 4
    "lbLabelFontHeightF" : .011
    "lbMonoFillPattern" : True
    "lbPerimOn" : False 
    "lbBoxCount" : 4 
    "lbLabelFontColor" : "white"
    "lbFillColors" : (/ 2,3,5,9 /)
    "lbLabelAlignment" : "BoxCenters"
    "lbLabelStrings" : (/"SNOW","ICE PELLETS","FREEZING RAIN","RAIN"/)
    "vpXF"      : 0.15 
    "vpYF"      : vpy - vpheight
    "vpWidthF"  : vpwidth-0.26
    "vpHeightF" : 0.04
end create
;
;if ( theos .ne. "AIX") then
;  modl = "WRF-RR "
;else
;  modl = "DWFE ARW "
;end if
;
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
; Draw map
;
draw(cnid)
draw(mpid)
draw(lbid)
frame(wid)
;
end
;
