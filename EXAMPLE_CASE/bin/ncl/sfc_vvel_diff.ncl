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

debug = 0
aname = asciiread("arw1_file.txt",-1,"string")
  arw1_file = addfile(aname,"r")
nname = asciiread("arw2_file.txt",-1,"string")
  arw2_file = addfile(nname,"r")

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
;
  smpl = arw1_file->lv_ISBL_103(:)

  do i = 0, 8
   print(i)
   print(smpl(i))
  end do

end if
  intm = arw1_file->TMP_GDS3_HTGL_10@initial_time
  fctm = arw1_file->TMP_GDS3_HTGL_10@forecast_time
  lat = arw1_file->g3_lat_0(:,:)
  lon = arw1_file->g3_lon_1(:,:)
  latin1 = arw1_file->g3_lon_1@Latin1
  latin2 = arw1_file->g3_lon_1@Latin2
  lov = arw1_file->g3_lon_1@Lov

  if (fctm .gt. 0)
    avv7 = arw1_file->V_VEL_GDS3_ISBL_10(26,:,:)
    avv5 = arw1_file->V_VEL_GDS3_ISBL_10(18,:,:)
    amnvv = (avv7 + avv5) / 2
    nvv7 = arw2_file->V_VEL_GDS3_ISBL_10(26,:,:)
    nvv5 = arw2_file->V_VEL_GDS3_ISBL_10(18,:,:)
    nmnvv = (nvv7 + nvv5) / 2
    diff = amnvv - nmnvv
  else
    hvar = arw1_file->HGT_GDS3_ISBL_10(18,:,:)
    mnvv = (hvar * 0.0)
    mnvv(1,:) = 7.0
    diff = mnvv
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
           "wkMetaName" : "./sfc_vvel.ncgm"
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
    "sfDataArray" : diff
    "sfXCStartV" : 0
    "sfYCStartV" : 0
    "sfXCEndV" : ydim
    "sfYCEndV" : xdim
    "sfMissingValueV" : -999.0
end create
;
;fillindices = ispan(2,43,1) ; Create array with indices to the colormap
;                           ; (skips first two colormap entries which
;                           ; are the background and foreground colors)
;
; Create a ContourPlot object.
;
; Vertical Velocity
;
cnid = create "contourplot" contourPlotClass wid
    "cnScalarFieldData":  mfield
    "cnLevelSelectionMode" : "ExplicitLevels"
    "cnMonoLineColor" : False
    "cnLevels" : (/-50,-20,-10,-4,-2,-1,-0.4,-0.2,0,0.2,0.4,1,2,4,10,20,50/)
    "cnFillColors" : (/ 24,23,21,19,17,15,13,11,1,1,28,29,30,31,33,35,39,43 /)
    "cnFillOn" : True
    "cnLinesOn" : False
    "cnLineLabelsOn" : False
    "cnInfoLabelOn" : False
    "cnMissingValFillColor" : "Foreground"
    "cnRasterModeOn" : True
    "tiMainString" : "700-500mb mean Vert Vel (Pa/s) Diff ("+title+")"
    "tiMainFont" : 22
    "tiMainFontHeightF" : .02
    "tiMainFontColor" : 43
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
draw(mpid)
frame(wid)
;
end
;
