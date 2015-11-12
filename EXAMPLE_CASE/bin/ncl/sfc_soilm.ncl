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
res = getenv ("RES")
;
begin

debug = 0
fname = asciiread("arw1_file.txt",-1,"string")
  grb_file = addfile(fname,"r")

if (debug.eq.1) then
  names = getfilevarnames(grb_file)  ; Get the variable names in the
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
;    test = grb_file->lv_DBLL3(:)
;    print (test)
  end do
end if
;
if (modl .eq. "WRF-RR RUC-13 " .or. modl .eq. "WRFRUC RUC-13 ") then
  T_HTGL="T_"+res+"_HTGL"
  intm = grb_file->$T_HTGL$@initial_time
  fctm = grb_file->$T_HTGL$@forecast_time
  gridlat="gridlat_"+res
  lat = grb_file->$gridlat$(:,:)
  gridlon="gridlon_"+res
  lon = grb_file->$gridlon$(:,:)
  latin1 = grb_file->$gridlon$@Latin1
  latin2 = grb_file->$gridlon$@Latin2
  lov = grb_file->$gridlon$@Lov

  tvar = grb_file->$T_HTGL$(:,:) - 273.15   
  ;tvar = tvar * 9/5 + 32 ; Convert to F
  UW_HTGL="UW_"+res+"_HTGL"
  uvar = grb_file->$UW_HTGL$(:,:)
  ; * 1.9429 ; convert to knots
  VW_HTGL="VW_"+res+"_HTGL"
  vvar = grb_file->$VW_HTGL$(:,:)
  ; * 1.9429 ; convert to knots
else  
  TMP_HTGL = "TMP_"+res+"_HTGL"
  intm = grb_file->$TMP_HTGL$@initial_time
  fctm = grb_file->$TMP_HTGL$@forecast_time
  gridlat="gridlat_"+res
  lat = grb_file->$gridlat$(:,:)
  gridlon="gridlon_"+res
  lon = grb_file->$gridlon$(:,:)
  latin1 = grb_file->$gridlon$@Latin1
  latin2 = grb_file->$gridlon$@Latin2
  lov = grb_file->$gridlon$@Lov
  lev = (/ 0, 1, 2, 3 /)
  print (lev)

  levnam = (/ "0-10", "10-40", "40-100", "100-200" /)
  lbstrd = (/ 2, 2, 2, 2 /)
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
             sprinti("%0.4i", year) + " " + sprinti("%0.2i:00 ", hour)  + \
             "UTC"

print(date_str)

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
           "wkMetaName" : "./sfc_soilm.ncgm"
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
   "wkColorMap" : "WhBlGrYeRe"
end setvalues
;
setvalues NhlGetWorkspaceObjectId()
   "wsMaximumSize": 247108864
end setvalues
;

if (res.ne."91") then
  mpid = create "mapplot" mapPlotClass wid 
    "mpProjection" : "LambertConformal"
    "mpLambertParallel1F" : latin1
    "mpLambertParallel2F" : latin2
    "mpLimitMode" : "Corners"    ; Limit the map view.
    "mpLambertMeridianF" : lov
    "mpLeftCornerLonF" : LcLon
    "mpLeftCornerLatF" : LcLat
    "mpRightCornerLonF" : RcLon
    "mpRightCornerLatF" : RcLat
    "mpOutlineBoundarySets" : "AllBoundaries"
    "mpNationalLineColor" : "background"
    "mpUSStateLineColor" : "background"
    "mpUSStateLineThicknessF" : 1.25
    "mpGridAndLimbOn" : False
    "mpGeophysicalLineColor" : "background"
    "mpPerimLineThicknessF" : 1.5
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy
    "vpWidthF"  : vpwidth 
    "vpHeightF" : vpheight
  end create
else
  mpid = create "mapplot" mapPlotClass wid 
    "mpProjection" : "Stereographic"
    "mpLimitMode" : "Corners"    ; Limit the map view.
    "mpLeftCornerLonF" : LcLon
    "mpLeftCornerLatF" : LcLat
    "mpRightCornerLonF" : RcLon
    "mpRightCornerLatF" : RcLat
    "mpCenterLonF" : lov
    "mpCenterLatF" : 90.
    "mpOutlineBoundarySets" : "AllBoundaries"
    "mpNationalLineColor" : "background"
    "mpUSStateLineColor" : "background"
    "mpUSStateLineThicknessF" : 1.25
    "mpGridAndLimbOn" : False
    "mpGeophysicalLineColor" : "background"
    "mpPerimLineThicknessF" : 1.5
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy
    "vpWidthF"  : vpwidth 
    "vpHeightF" : vpheight
  end create
end if


;;
;; Surface Soil Moisture
;;
;  soilm = grb_file->SOIL_M_GDS3_DBLY(:,:)
;
;print("sfc soilm")
;print(min(soilm))
;print(max(soilm))
;
;; Create ScalarField objects.
;;
;; Geopotential Height
;;
;smfield = create "ScalarField" scalarFieldClass appid
;    "sfDataArray" : soilm
;    "sfXCStartV" : 0
;    "sfYCStartV" : 0
;    "sfXCEndV" : ydim
;    "sfYCEndV" : xdim
;    "sfMissingValueV" : -999.0
;end create
;
;;
;; Create ContourPlot objects.
;;
;cnid = create "contourplot" contourPlotClass wid
;    "cnScalarFieldData":  smfield
;    "cnFillColors" : (/ 1,3,5,8,11,13,14,16,17,18,20,21,23,24,26,27,50,52,56,60,64,68,72,74,76,78,80,82,84,86,88,90,92,94,96,98,100,102 /)
;    ;"cnFillColors" : (/ 1,10,20,30,40,50,60,70,80,90,1,1 /)
;    "cnLevelSelectionMode" : "ManualLevels"
;    "cnMinLevelValF" :  0.00001 
;    "cnMaxLevelValF" : 0.57
;    "cnLevelSpacingF" : 0.015
;    "cnFillOn" : True
;    "cnLinesOn" : False
;    "cnLineLabelsOn" : False
;    "cnInfoLabelOn" : False
;    "cnRasterModeOn" : True
;    "pmTickMarkDisplayMode" : "NoCreate"
;    "pmLabelBarDisplayMode" : "ALWAYS"
;    "pmLabelBarHeightF" : .05
;    "pmLabelBarWidthF" : 0.9
;    "pmLabelBarSide" : "bottom"
;    "pmLabelBarOrthogonalPosF" : 0.0
;    "lbOrientation" : "horizontal"
;    "lbTitleFont" : 22 
;    "lbTitleFontHeightF" : 0.001 
;    "lbPerimOn" : False
;    "lbBoxLinesOn" : 0
;    "lbLabelStride" :  2
;    "tiMainString" : "Surface Soil Moisture"
;    "tiMainFont" : 22
;    "tiMainFontHeightF" : .02
;    "tiMainFontColor" : 78
;    "tiMainJust" : "CenterCenter"
;    "tiMainOffsetYF" : -0.013
;    "vpXF"      : vpx        ; set viewport
;    "vpYF"      : vpy       
;    "vpWidthF"  : vpwidth
;    "vpHeightF" : vpheight
;end create
;;
;txid = create "TextItems" textItemClass wid
;  "txFuncCode" : "~"
;  "txString" : title+intm+" "+fctm+" hr fcst"
;  "txFont" : 22
;  "txFontHeightF" : 0.015
;  "txFontColor" : 1
;end create
;;
;txid2 = create "TextItems" textItemClass wid
;  "txFuncCode" : "~"
;  "txString" : date_str
;  "txFont" : 22
;  "txFontHeightF" : 0.015
;  "txFontColor" : 1
;end create
;;
;ianno = NhlAddAnnotation(cnid,txid)
;setvalues ianno
;  "amZone":           10
;  "amSide":           "top"
;  "amJust":           "bottomleft"
;  "amParallelPosF":    0.0
;  "amOrthogonalPosF":  0.018
;end setvalues
;ianno2 = NhlAddAnnotation(cnid,txid2)
;setvalues ianno2
;  "amZone":           10
;  "amSide":           "top"
;  "amJust":           "bottomright"
;  "amParallelPosF":    1.0
;  "amOrthogonalPosF":  0.018
;end setvalues
;;
;; Draw map of <level>mb Winds
;;
;draw(cnid)
;draw(mpid)
;frame(wid)
;;

  do i = 0, 3
  
  SOILW_DBLY = "SOILW_"+res+"_DBLY"
  soilm_ll = grb_file->$SOILW_DBLY$(lev(i),:,:)

print(levnam(i))
print("soilm_ll")
print(min(soilm_ll))
print(max(soilm_ll))

;
; Create ScalarField objects.
;
; Geopotential Height
;
smfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : soilm_ll
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
;    "sfMissingValueV" : -999.0
    "sfMissingValueV" : 1e+20
end create

;
; Create ContourPlot objects.
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  smfield
    "cnFillColors" : (/ 1,3,4,5,6,8,9,10,11,14,15,17,18,20,21,23,24,27,52,56,58,60,64,68,72,74,75,76,78,80,82,84,86,88,90,92,94,96,98,99,100,102 /)
;    "cnFillColors" : (/ 1,10,20,30,40,50,60,70,80,90,1,1 /)
;    "cnFillColors" : (/ 1,3,5,8,11,13,14,16,17,18,20,21,23,24,26,27,50,52,56,60,64,68,72,74,76,78,80,82,84,86,88,90,92,94,96,98,100,102 /)
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" :  0.00001 
    "cnMaxLevelValF" : 0.57
    "cnLevelSpacingF" : 0.015
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
    "lbOrientation" : "horizontal"
    "lbTitleFont" : 22 
    "lbPerimOn" : False
    "lbBoxLinesOn" : 0
    "lbLabelStride" :  lbstrd(i)
    "lbLabelFontHeightF" : 0.06
    "tiMainString" : levnam(i) + "cm level Soil Moisture"
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
;
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
; Draw map of <level>mb Winds
;
draw(cnid)
draw(mpid)
frame(wid)
;
end do
end
;
