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
;
  smpl = grb_file->lv_ISBL_103(:)

  do i = 0, 8
   print(i)
   print(smpl(i))
  end do

end if

;do i=0, 1

  intm = grb_file->TMP_GDS0_HTGL@initial_time
  fctm = grb_file->TMP_GDS0_HTGL@forecast_time
  lat = grb_file->g0_lat_0(:)
  lon = grb_file->g0_lon_1(:)
  lat1 = grb_file->g0_lon_1@La1
  lat2 = grb_file->g0_lon_1@La2
  lon1 = grb_file->g0_lon_1@Lo1
  lon2 = grb_file->g0_lon_1@Lo2

  uvar = grb_file->U_GRD_GDS0_ISBL(26,:,:) 
;* 1.9429 ; convert to knots
  vvar = grb_file->V_GRD_GDS0_ISBL(26,:,:) 
;* 1.9429 ; convert to knots
  rh85 = grb_file->R_H_GDS0_ISBL(32,:,:)

  uv2 = uvar * uvar
  vv2 = vvar * vvar
  wind = sqrt(uv2 + vv2) + 0.00001


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

  LcLon = lon(point2)
  LcLat = lat(point2)
  RcLon = lon(0)
  RcLat = lat(0)
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
           "wkMetaName" : "./ua_rh8.ncgm"
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
mfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : rh85
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
end create
;
; Create a VectorField object.
;
vfield = create "VectorField" vectorFieldClass appid
    "vfUDataArray" : uvar
    "vfVDataArray" : vvar
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
    "vcWindBarbLineThicknessF" : 1.2
    "vcWindBarbColor" : 0
    "vcRefAnnoOn" : False
    "vcWindBarbTickSpacingF" : 0.1875
    "pmTickMarkDisplayMode" : "NoCreate"
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;
; Create a ContourPlot object.
;
; Mean RH
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  mfield
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" :  0
    "cnMaxLevelValF" : 100
    "cnLevelSpacingF" : 10 
    "cnMonoLineColor" : False
    "cnFillColors" : (/ 0,112,2,10,25,7,17,32,71,41,159,144 /)
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnLineLabelsOn" : False
    "cnInfoLabelOn" : False
    "cnMissingValFillColor" : "Background"
    "cnRasterModeOn" : True
    "cnGridBoundPerimOn" : True
    "tiMainString" : "850mb Rel Hum (%)"
;    "tiMainString" : tlnam
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 146
    "tiMainOffsetYF" : -0.013
    "pmTickMarkDisplayMode" : "NoCreate"
    "pmLabelBarDisplayMode" : "ALWAYS"
    "pmLabelBarHeightF" : .05
    "pmLabelBarWidthF" : 0.9
    "pmLabelBarSide" : "bottom"
    "pmLabelBarOrthogonalPosF" : 0.0
    "lbOrientation" : "horizontal"
    "lbTitleFont" : 22 
    "lbPerimOn" : False
    "lbLabelStride" : 1 
    "lbBoxLinesOn" : 0
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;
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
; Draw map of 700-500 VVel
;
draw(cnid)
;draw(vcid)
draw(mpid)
frame(wid)
end
;
