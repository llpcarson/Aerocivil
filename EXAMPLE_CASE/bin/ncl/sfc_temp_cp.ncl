;
load "$NCARG_LIB/ncarg/nclscripts/csm/contributed.ncl"
theos = systemfunc("uname")
modl = getenv("MODEL") + " "
title = getenv ("TITLE") + " "
point1_str = getenv ("POINT1")
point2_str = getenv ("POINT2")
nxin_str = getenv ("NXIN")
nyin_str = getenv ("NYIN")
stride = getenv ("STRIDE")
;
begin

debug = 0
fname = asciiread("arw1_file.txt",-1,"string")
  grb_file = addfile(fname,"r")

  if (debug.eq.1) then
  names = getfilevarnames(grb_file)
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
  intm = grb_file->TMP_GDS3_HTGL@initial_time
  fctm = grb_file->TMP_GDS3_HTGL@forecast_time
  lat = grb_file->g3_lat_0(:,:)
  lon = grb_file->g3_lon_1(:,:)
  latin1 = grb_file->g3_lon_1@Latin1
  latin2 = grb_file->g3_lon_1@Latin2
  lov = grb_file->g3_lon_1@Lov

  tvar = grb_file->TMP_GDS3_HTGL(:,:) - 273.15   
;*  tvar = tvar * 9/5 + 32 ; Convert to F
  uvar = grb_file->U_GRD_GDS3_HTGL(:,:) 
;* 1.9429 ; convert to knots
  vvar = grb_file->V_GRD_GDS3_HTGL(:,:) 
;* 1.9429 ; convert to knots
  rot = grb_file->g3_rot_2(:,:)

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

  uearth = sin(rot)*vvar + cos(rot)*uvar
  vearth = cos(rot)*vvar - sin(rot)*uvar

  uv2 = uearth * uearth
  vv2 = vearth * vearth
  wind = sqrt(uv2 + vv2) + 0.00001

print(month)
  if (month .eq. 12 .or. (month .ge. 1 .and. month .le. 2)) then
;     minval = -28
;     maxval = 92
;     dmklvl = 32
     minval = -32
     maxval = 48
     dmklvl = 0
  else
     if ((month .ge. 3 .and. month .le. 5) .or. (month .ge. 9 .and. month .le. 11)) then
;        minval = -10
;        maxval = 110
;        dmklvl = 50
        minval = -32
        maxval = 48
        dmklvl = 0
     else
;        minval = 8
;        maxval = 128
;        dmklvl = 68
        minval = -32
        maxval = 48
        dmklvl = 0
     end if
   end if

print(date_str)
print("temp")
print(min(tvar))
print(max(tvar))
print("wind")
print(min(wind))
print(max(wind))

  point1 = stringtoint(point1_str)
  point2 = stringtoint(point2_str)
  nxin   = stringtoint(nxin_str)
  nyin   = stringtoint(nyin_str)

  LcLon = lon(point1,point2)
  LcLat = lat(point1,point2)
  RcLon = lon(0,0)
  RcLat = lat(0,0)
;
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
           "wkMetaName" : "./sfc_temp.ncgm"
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
;   "wkColorMap" : "wh-bl-gr-ye-re"
;   "wkColorMap" : "WhViBlGrYeOrReWh"
   "wkColorMap" : "WhBlGrYeRe"
end setvalues
;

setvalues NhlGetWorkspaceObjectId()
   "wsMaximumSize": 247108864
end setvalues
;
mpid = create "mapplot" mapPlotClass wid 
;
  "mpProjection" : "LambertConformal"
  "mpLambertParallel1F" : latin1
  "mpLambertParallel2F" : latin2
;
  "mpLimitMode" : "Corners"    ; Limit the map view.
  "mpLambertMeridianF" : lov
  "mpLeftCornerLonF" : LcLon
  "mpLeftCornerLatF" : LcLat
  "mpRightCornerLonF" : RcLon
  "mpRightCornerLatF" : RcLat
  "mpOutlineBoundarySets" : "AllBoundaries"
  "mpUSStateLineColor" : "background"
  "mpUSStateLineThicknessF" : 1.25
  "mpGridAndLimbOn" : False
  "mpGeophysicalLineColor" : "background"
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
tfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : tvar
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
;    "sfMissingValueV" : -10000.0
    "sfMissingValueV" : -999.0
end create
;
; Create a VectorField object.
;
vfield = create "VectorField" vectorFieldClass appid
    "vfUDataArray" : uearth
    "vfVDataArray" : vearth
    "vfXCStartV" : 0
    "vfYCStartV" : 0
    "vfXCEndV" : ydim
    "vfYCEndV" : xdim
    "vfMissingVValueV" : -999.0
    "vfMissingUValueV" : -999.0
    "vfXCStride" : stride          ; i.e., plot a vector at every (n+1)th point.
    "vfYCStride" : stride 
end create
;
; Create a VectorPlot object.
;
vcid = create "vectorplot" vectorPlotClass wid
    "vcVectorFieldData":  vfield
    "vcGlyphStyle" : "WindBarb"
    "vcMinDistanceF" : 0.002
    "vcWindBarbLineThicknessF" : 1.2 
    "vcWindBarbColor" : 0
    "vcRefAnnoOn" : False
    "vcWindBarbTickSpacingF" : 0.1875
    "pmTickMarkDisplayMode" : "NoCreate"
    "tiMainString" : "Sfc Temp (C), Wind (m/s)"
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 78
    "tiMainJust" : "CenterCenter"
    "tiMainOffsetYF" : -0.013
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create

;if ( theos .ne. "AIX") then
;  modl = "WRF-RR "
;else
;  modl = "DWFE ARW "
;end if

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
ianno = NhlAddAnnotation(vcid,txid)
setvalues ianno
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomleft"
  "amParallelPosF":    0.0
  "amOrthogonalPosF":  0.018
end setvalues
ianno2 = NhlAddAnnotation(vcid,txid2)
setvalues ianno2
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomright"
  "amParallelPosF":    1.0
  "amOrthogonalPosF":  0.018
end setvalues

setvalues vcid
  "vcMinMagnitudeF" : 0
end setvalues
;
; Create a ContourPlot object.
;
; Surface Temperature
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  tfield
;    "cnFillColors" : (/ 1,13,21,28,35,43,50,57,65,72,79,87,94,101,109,116,123,131,138,145,153,160,167,175,182,189 /)
;    "cnFillColors" : (/ 1,2,3,4,5,6,7,8,9,11,14,17,19,22,24,27,29,32,34,37,39,42,44,47,49,52,54,57,59,62,64,67,69,72,74,77,79,82,84,87,89,92,94,97 /)
;old    "cnFillColors" : (/ 1,3,4,5,6,7,8,9,10,11,12,14,16,18,20,22,24,26,28,30,32,52,56,60,64,68,72,74,76,78,80,82,84,86,88,90,92,94,96,98,100,102 /)
;    "cnFillColors" : (/ 1,3,4,5,6,7,8,9,10,11,12,14,15,17,18,20,21,23,24,26,27,52,56,60,64,68,72,74,76,78,80,82,84,86,88,90,92,94,96,98,100,102 /)
    "cnFillColors" : (/ 1,3,4,5,6,8,9,11,14,15,17,18,20,21,23,24,27,52,56,58,60,62,64,68,72,74,75,76,78,80,82,84,86,88,90,92,94,96,98,99,100,102 /)
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" :  minval
    "cnMaxLevelValF" : maxval
    "cnLevelSpacingF" : 2 
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnLineLabelsOn" : False
    "cnInfoLabelOn" : False
    "cnGridBoundPerimOn" : True
    "cnRasterModeOn" : True
    "pmTickMarkDisplayMode" : "NoCreate"
    "pmLabelBarDisplayMode" : "ALWAYS"
    "pmLabelBarHeightF" : .05
    "pmLabelBarWidthF" : 0.9
    "pmLabelBarSide" : "bottom"
    "pmLabelBarOrthogonalPosF" : 0.0
    "lbOrientation" : "horizontal"
    "lbTitleFont" : 22 
    "lbPerimOn" : False
    "lbBoxLinesOn" : 0
    "lbLabelStride" : 2
    "lbLabelFontHeightF" : 0.06
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;
cnid5 = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  tfield
    "cnLevelSelectionMode" : "ExplicitLevels"
    "cnLevels" : dmklvl 
    "cnLineThicknessF" : 2.0
    "cnMonoLineColor" : False
    "cnLineColors" : (/1/)
    "cnLineLabelFontHeightF" : 0.009
    "cnLineLabelPlacementMode" : "Computed"
    "cnInfoLabelOn" : False
    "pmTickMarkDisplayMode" : "NoCreate"
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;
; Draw map of Sfc Temp, Winds
;
draw(cnid)
draw(cnid5)
draw(vcid)
draw(mpid)
frame(wid)
;
end
