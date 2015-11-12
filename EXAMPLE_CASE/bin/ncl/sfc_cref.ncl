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
        ; Set rgb colors

        ; The continental outlines in the map object use this color
        ; as a default.

        return( (/ \
         (/0.00,0.00,0.00/), \  ; white      0
         (/1.00,1.00,1.00/), \  ; black      1
         (/0.00,0.00,1.00/), \  ; blue       2
         (/0.20,0.56,0.80/), \  ; sky blue   3
         (/0.00,1.00,1.00/), \  ; cyan       4
         (/0.50,0.00,1.00/), \  ; blue magenta   5
         (/0.00,1.00,0.00/), \  ; green      6
         (/0.14,0.56,0.14/), \  ; forest green   7
         (/1.00,1.00,0.00/), \  ; yellow      8
         (/1.00,0.50,0.00/), \  ; orange     9
         (/1.00,0.00,1.00/), \ ; magenta   10
         (/1.00,0.00,0.00/), \ ; red       11
         (/0.65,0.16,0.16/), \ ; brown     12
         (/0.86,0.58,0.44/), \ ; tan       13
         (/0.63,0.13,0.94/), \ ; purple    14
         (/0.93,0.51,0.94/), \ ; violet    15
         (/0.00,0.00,0.50/), \ ; navy      16
         (/0.00,0.00,0.80/), \ ; medium blue  17
         (/1.00,0.75,0.80/), \ ; pink        18
         (/0.55,0.24,0.18/), \ ; coral       19
         (/0.60,0.98,0.60/), \ ; pale green     20
         (/1.00,0.76,0.15/), \ ; goldenrod      21
         (/0.66,0.66,0.66/), \ ; light gray    22
         (/0.40,0.40,0.40/) /) ) ; dark gray   23

end
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
; smpl = grb_file->lv_ISBL_103(:)

; do i = 0, 8
;  print(i)
;  print(smpl(i))
; end do
end if

  intm = grb_file->TMP_GDS3_HTGL@initial_time
  fctm = grb_file->TMP_GDS3_HTGL@forecast_time
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

  lat = grb_file->g3_lat_0(:,:)
  lon = grb_file->g3_lon_1(:,:)
  latin1 = grb_file->g3_lon_1@Latin1
  latin2 = grb_file->g3_lon_1@Latin2
  lov = grb_file->g3_lon_1@Lov
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

  LcLon = lon(point1,point2)
  LcLat = lat(point1,point2)
  RcLon = lon(0,0)
  RcLat = lat(0,0)
;lrb end if
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
           "wkMetaName" : "./sfc_cref.ncgm"
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
  "mpPerimOn" : True
  "vpXF"      : vpx        ; set viewport
  "vpYF"      : vpy
  "vpWidthF"  : vpwidth 
  "vpHeightF" : vpheight
;
end create

;if ( theos .ne. "AIX") then
  cref = grb_file->REFC_GDS3_EATM(:,:) 
;else
;  cref = grb_file->VAR_212_163_EATM(:,:) 
;end if
if ( fctm .eq. 0 ) then   ; need to fool it at hour 0
  cref(1,1) = 5.1
end if

print("cref")
print(min(cref))
print(max(cref))
;
; Create a ScalarField object.
;
tfield = create "ScalarField" scalarFieldClass appid
    "sfDataArray" : cref
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
end create
;
; Create a ContourPlot object.
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  tfield
    "cnRasterModeOn":  True
    "cnLevelSelectionMode" : "ExplicitLevels"
    "cnLevels" : (/ 0.,5.,10.,15.,20.,25.,30.,35.,40.,45.,50.,55.,60.,65.,70.,75. /)
;   "cnFillColors" : (/0,0,14,15,16,2,17,4,7,6,8,11,9,18,14,0,20 /)   ; original
    "cnFillColors" : (/1,1,4,3,2,20,6,7,8,21,9,11,19,18,15,14,0  /)    ; greg's
    "cnMinLevelValF" :  0
    "cnMaxLevelValF" :  75
    "cnLevelSpacingF" : 3 
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnLineLabelsOn" : False
    "cnInfoLabelOn" : False
    "pmTickMarkDisplayMode" : "NoCreate"
    "pmLabelBarDisplayMode" : "ALWAYS"
    "pmLabelBarHeightF" : .05
    "pmLabelBarWidthF" : 0.9
    "pmLabelBarSide" : "bottom"
    "pmLabelBarOrthogonalPosF" : 0.0
    "lbOrientation" : "horizontal"
    "lbTitleFont" : 22 
    "lbPerimOn" : False
    "lbBoxLinesOn" : True
    "tiMainString" : "Composite Reflectivity (dBZ)"
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 1
    "tiMainOffsetYF" : -0.013
    "vpXF"      : vpx        ; set viewport
    "vpYF"      : vpy       
    "vpWidthF"  : vpwidth
    "vpHeightF" : vpheight
end create
;

;      Set  "mpPerimOn" : "True"   and
;      set "lbBoxLinesOn" : "True"

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
; Draw map 
;
draw(cnid)
draw(mpid)
frame(wid)
;
end
;
