;
load "$NCARG_LIB/ncarg/nclscripts/csm/contributed.ncl"
theos = systemfunc("uname")
modl  = getenv("MODEL") + " "
title = getenv ("TITLE") + " "
point1_str = getenv ("POINT1")
point2_str = getenv ("POINT2")
nxin_str = getenv ("NXIN")
nyin_str = getenv ("NYIN")
;
begin

  debug = 0

  ; Read the input file names from an ascii file
  fnames    = asciiread("arw1_file.txt",-1,"string")
  fname_grb = fnames(0)
  fname_nc  = fnames(1)

  ; Read the GRIB file
  grb_file = addfile(fname_grb,"r")

  if (debug.eq.1) then
    names = getfilevarnames(grb_file) ; Get the GRIB file variable names
    print(names)                      ; Print out the variable names
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
    delete(names)
  end if

  ; Get the init and forecast times
  intm = grb_file->TMP_GDS0_HTGL@initial_time
  fctm = grb_file->TMP_GDS0_HTGL@forecast_time

  ; Get the projection information
  lat    = grb_file->g0_lat_0(:)
  lon    = grb_file->g0_lon_1(:)
  lat1   = grb_file->g0_lon_1@La1
  lat2   = grb_file->g0_lon_1@La2
  lon1   = grb_file->g0_lon_1@Lo1
  lon2   = grb_file->g0_lon_1@Lo2

  ; Get the mean sea-level pressure and thickness
  mvar  = grb_file->MSLET_GDS0_MSL(:,:) * .01
  h5    = grb_file->HGT_GDS0_ISBL(18,:,:)
  h10   = grb_file->HGT_GDS0_ISBL(38,:,:)
  thick = (h5 - h10) / 10

  ; Get the 3-hour accumulated precip
  if ( fctm .eq. 0 ) then
    tvar      = (mvar * 0.0) ; at hour zero create a zero-filled array
    tvar(1,1) = 0.011        ; there must be at least .01 somewhere in the domain or the contouring will fail
  else

    ; Read the 3-hour precip from a wrfpcp NetCDF file
    nc_file = addfile(fname_nc,"r")

    if (debug.eq.1) then
      names = getfilevarnames(nc_file) ; Get the NetCDF variable names
      print(names)                     ; Print out the variable names

      do i = 0, dimsizes( names ) - 1
        print("Variable Name: " + names(i))
        dims = getfilevardims(nc_file,names(i))
        sizes = filevardimsizes(nc_file,names(i))
        print(dimsizes(sizes) + " Dimensions:")
        if(.not.any(ismissing(dims))) then
          do j = 0, dimsizes(dims) -1
            print( j + ") " + dims(j) + ": " + sizes(j))
          end do
        end if
        atts = getfilevaratts(nc_file,names(i))
        if(.not.any(ismissing(atts))) then
          do k = 0, dimsizes(atts) -1
            print(atts(k) + ": " +nc_file->$names(i)$@$atts(k)$)
          end do
        end if
        delete(atts)
        delete(dims)
        delete(sizes)
        print("")
      end do
      delete(names)
    end if

    ; Read the 3-hour accumulated precip
    tvar = nc_file->APCP_03 * 0.03937 ; convert mm to inches

  end if

  if (fctm .gt. 0)
    j = 1
  else
    j = 0
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
 
  print(date_str)
  print("acp")
  print(min(tvar))
  print(max(tvar))
  print("slp")
  print(min(mvar))
  print(max(mvar))

  point1 = stringtoint(point1_str)
  point2 = stringtoint(point2_str)
  nxin   = stringtoint(nxin_str)
  nyin   = stringtoint(nyin_str)

  LcLon = lon(point2)
  LcLat = lat(point2)
  RcLon = lon(0)
  RcLat = lat(0)

  tlnam = (/ "MSLP (mb), 1000-500 Thick (dm)", "3-h Total Precip (in), MSLP (mb), 1000-500 Thick (dm)" /)

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
           "wkMetaName" : "./sfc_acp.ncgm"
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
; Create ScalarField objects.
;
tfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : tvar
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
end create
mfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : mvar
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
end create
zfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : thick
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
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
;
; Create ContourPlot objects.
;
; 3-h Total precip
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  tfield
    "cnMonoLineColor" : False
    "cnLevels" : (/0.01, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.75, 1, 1.25, 1.5, 2, 2.5, 3, 4, 5/)
    "cnFillColors" : (/1,4,10,35,40,45,159,76,46,161,12,22,103,11,31,102,91,66,141 /)
    "cnLevelSelectionMode" : "ExplicitLevels"
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnInfoLabelOn" : False
    "cnLineLabelsOn" : False 
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
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;
; MSLP
;
cnid4 = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  mfield
    "cnFillOn" : False
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" : 900
    "cnMaxLevelValF" : 1100
    "cnLevelSpacingF" : 2
    "cnLevelFlags" : (/"LineAndLabel"/) 
    "cnInfoLabelOn" : False 
    "cnLinesOn" : True
    "cnLineColor" : 88
    "cnLineLabelsOn" : True
    "cnLineLabelInterval" : 2 
    "cnLineLabelFont" : 21
    "cnLineLabelFontHeightF" : 0.008
    "cnLineLabelFontColor" : "Background"
    "cnLineLabelBackgroundColor" : "Foreground"
    "cnLineLabelPlacementMode" : "Computed"
    "cnLineThicknessF" : 1.0
    "pmTickMarkDisplayMode" : "NoCreate"
    "tiMainString" : tlnam(j)
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 146
    "tiMainJust" : "CenterCenter"
    "tiMainOffsetYF" : -0.013
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;
; Thickness
;
cnid5 = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  zfield
    "cnFillOn" : False
    "cnLevelSelectionMode" : "ManualLevels"
    "cnMinLevelValF" : 402
    "cnMaxLevelValF" : 600
    "cnLevelSpacingF" : 6
    "cnLevelFlags" : (/"LineAndLabel"/) 
    "cnInfoLabelOn" : False 
    "cnLinesOn" : True
    "cnLineColor" : 66
    "cnLineLabelsOn" : True
    "cnLineLabelInterval" : 2 
    "cnLineLabelFont" : 21
    "cnLineLabelFontHeightF" : 0.008
    "cnLineLabelFontColor" : "Background"
    "cnLineLabelBackgroundColor" : "Foreground"
    "cnLineLabelPlacementMode" : "Computed"
    "cnLineThicknessF" : 2.0
    "pmTickMarkDisplayMode" : "NoCreate"
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;
ianno = NhlAddAnnotation(cnid4,txid)
setvalues ianno
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomleft"
  "amParallelPosF":    0.0
  "amOrthogonalPosF":  0.018
end setvalues
ianno2 = NhlAddAnnotation(cnid4,txid2)
setvalues ianno2
  "amZone":           10
  "amSide":           "top"
  "amJust":           "bottomright"
  "amParallelPosF":    1.0
  "amOrthogonalPosF":  0.018
end setvalues
; Draw map of 3-h Acc Total Precip, MSLP
;
draw(cnid)
draw(cnid4)
draw(cnid5)
draw(mpid)
frame(wid)
;
end
;
