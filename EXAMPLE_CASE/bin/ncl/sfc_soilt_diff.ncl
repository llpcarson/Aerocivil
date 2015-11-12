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
aname = asciiread("arw1_file.txt",-1,"string")
  arw1_file = addfile(aname,"r")
nname = asciiread("arw2_file.txt",-1,"string")
  arw2_file = addfile(nname,"r")

  if (debug.eq.1) then
  names = getfilevarnames(arw1_file)
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
  intm = arw1_file->$TMP_HTGL$@initial_time
  fctm = arw1_file->$TMP_HTGL$@forecast_time
  gridlat = "gridlat_"+res
  gridlon = "gridlon_"+res
  lat = arw1_file->$gridlat$(:,:)
  lon = arw1_file->$gridlon$(:,:)
  latin1 = arw1_file->$gridlon$@Latin1
  latin2 = arw1_file->$gridlon$@Latin2
  lov = arw1_file->$gridlon$@Lov 

end if

  lev = (/ 0, 1, 2, 3 /)
  levnam = (/ "0-10", "10-40", "40-100", "100-200" /)
  lbstrd = (/ 2, 2, 2, 2 /)

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
;  print(vpx)
;  print(vpy)
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
           "wkMetaName" : "./sfc_soilt.ncgm"
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
    "wkColorMap" : "uniform"
end setvalues
;

;print("Last lat/lon is")
;print (lat(302,398))
;print (lon(302,398))

setvalues NhlGetWorkspaceObjectId()
   "wsMaximumSize": 247108864
end setvalues
;

 do i = 0, 3
  
  TSOILW_DBLY = "TSOILW_"+res+"_DBLY"
  atvar = arw1_file->$TSOIL_DBLY$(lev(i),:,:) - 273.15
  ;atvar = atvar * 9/5 + 32 ; Convert to F
  ntvar = arw2_file->$TSOIL_DBLY$(lev(i),:,:) - 273.15
  ;ntvar = ntvar * 9/5 + 32 ; Convert to F

  diff = atvar - ntvar

print(levnam(i))
print("soilt_ll atvar")
print(min(atvar))
print(max(atvar))
print("soilt_ll ntvar")
print(min(ntvar))
print(max(ntvar))
print("soilt_ll diff")
print(min(diff))
print(max(diff))

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
;
; Create a ScalarField object.
;
tfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : diff
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
;    "sfMissingValueV" : -999.0
    "sfMissingValueV" : 1e+20
end create

; Create a ContourPlot object.
;
; Surface Temp
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  tfield
    "cnFillColors" : (/ 98,27,17,12,7,95,25,15,10,5,1,1,41,46,51,56,162,171,63,112,88,141 /)
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" :  -20
    "cnMaxLevelValF" : 20
    "cnLevelSpacingF" : 2
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnLineLabelsOn" : False
    "cnInfoLabelOn" : False
    "cnGridBoundPerimOn" : False
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
    "lbLabelStride" : lbstrd(i)
    "lbLabelFontHeightF" : 0.06
    "tiMainString" : levnam(i) + "cm level Soil Temp (F) Diff ("+title+")"
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 141
    "tiMainJust" : "CenterCenter"
    "tiMainOffsetYF" : -0.013
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
txid = create "TextItems" textItemClass wid
  "txFuncCode" : "~"
  "txString" : title+intm+" "+fctm+" hr fcst"
  "txFont" : 22
  "txFontHeightF" : 0.018
  "txFontColor" : 1
end create
;
txid2 = create "TextItems" textItemClass wid
  "txFuncCode" : "~"
  "txString" : date_str
  "txFont" : 22
  "txFontHeightF" : 0.018
  "txFontColor" : 1
end create
ianno = NhlAddAnnotation(cnid,txid)
setvalues ianno
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomleft"
  "amParallelPosF":    0.0
  "amOrthogonalPosF":  0.015
end setvalues
ianno2 = NhlAddAnnotation(cnid,txid2)
setvalues ianno2
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomright"
  "amParallelPosF":    1.0
  "amOrthogonalPosF":  0.02
end setvalues
;
; Draw map of Sfc Moisture
;
draw(cnid)
draw(mpid)
frame(wid)
;
end do
end
;

