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
begin
  debug = 0

aname = asciiread("arw1_file.txt",-1,"string")
  arw1_file = addfile(aname,"r")
nname = asciiread("arw2_file.txt",-1,"string")
  arw2_file = addfile(nname,"r")
  names = getfilevarnames(arw1_file)  ; Get the variable names in the

aname_nc = asciiread("arw3_file.txt",-1,"string")
nname_nc = asciiread("arw4_file.txt",-1,"string")


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
;
  delete(names)
end if

  intm = arw1_file->TMP_GDS3_HTGL@initial_time
  fctm = arw1_file->TMP_GDS3_HTGL@forecast_time
  lat = arw1_file->g3_lat_0(:,:)
  lon = arw1_file->g3_lon_1(:,:)
  latin1 = arw1_file->g3_lon_1@Latin1
  latin2 = arw1_file->g3_lon_1@Latin2
  lov = arw1_file->g3_lon_1@Lov
  mvar = arw1_file->MSLET_GDS3_MSL(:,:) * .01

; Get the 3-hour accumulated precip from NetCDF file
  if ( fctm .eq. 0 ) then
    tvar = (mvar * 0.0) ; at hour zero create a zero-filled array
    tvar(1,1) = 0.011  ; there must be at least .01 somewhere in the domain or the contouring will fail
    diff = tvar
  else

    ; Read the 3-hour precip from a wrfpcp NetCDF file
    nc_file1 = addfile(aname_nc,"r")
    nc_file2 = addfile(nname_nc,"r")

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

    atvar = nc_file1->APCP_03 * 0.03937 ; convert to inches
    ntvar = nc_file2->APCP_03 * 0.03937 ; convert to inches
    diff = atvar - ntvar

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
  print(min(diff))
  print(max(diff))

  point1 = stringtoint(point1_str)
  point2 = stringtoint(point2_str)
  nxin   = stringtoint(nxin_str)
  nyin   = stringtoint(nyin_str)

  LcLon = lon(point1,point2)
  LcLat = lat(point1,point2)
  RcLon = lon(0,0)
  RcLat = lat(0,0)

  tlnam = (/ "3-h Total Precip (in) Diff ("+title+")" /)
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
    "sfDataArray" : diff
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
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
;
; Create ContourPlot objects.
;
; 3-h Total precip
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  tfield
    "cnMonoLineColor" : False
    "cnLevels" : (/-3, -2, -1.5, -1.25, -1, -0.75, -0.5, -0.25, -0.1, -0.05, 0., 0.05, 0.1, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3/)
    "cnFillColors" : (/ 98,27,17,12,7,95,25,15,10,5,1,1,41,46,51,56,162,171,63,112,88,141 /)
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
    "tiMainString" : tlnam
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 146
    "tiMainOffsetYF" : -0.013
    "lbOrientation" : "horizontal"
    "lbTitleFont" : 22 
    "lbPerimOn" : False
    "lbBoxLinesOn" : 0
    "lbLabelStride" : 1
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
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
; Draw map of 3-h Acc Total Precip
;
draw(cnid)
draw(mpid)
frame(wid)
;
end
;
