;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;************************************************
;*******************************************************************************
;This script computes the U and V components of IVT from a CFSR grb file 
;and dumps the result in a netcdf file
;
;KM Mod for WRF files
;MH Mod for DTC workflows
;*******************************************************************************

theos = systemfunc("uname")
modl = getenv("MODEL") + " "
title = getenv ("TITLE") + " "
point1_str = getenv ("POINT1")
point2_str = getenv ("POINT2")
nxin_str = getenv ("NXIN")
nyin_str = getenv ("NYIN")
stride = getenv ("STRIDE")
domain = getenv ("DOMAIN")
begin

;*************************
; manual settings
;*************************

;title      = "AFWAOC"
;point1_str = 300
;point2_str = 401
;nxin_str   = 402
;nyin_str   = 301
;stride     = 10 ; will need to adjust

;*************************
;Load file and variables
;*************************

fname = asciiread("arw1_file.txt",-1,"string")

grb_file = addfile(fname,"r")
  
intm = grb_file->TMP_GDS0_HTGL@initial_time
fctm = grb_file->TMP_GDS0_HTGL@forecast_time
lat  = grb_file->g0_lat_0(:)
lon  = grb_file->g0_lon_1(:)
lat1 = grb_file->g0_lon_1@La1
lat2 = grb_file->g0_lon_1@La2
lon1 = grb_file->g0_lon_1@Lo1
lon2 = grb_file->g0_lon_1@Lo2

tk = grb_file->TMP_GDS3_ISBL(:,:,:)               ; Temperature (K)
u = grb_file->U_GRD_GDS3_ISBL(:,:,:)              ; U wind compontent (m/s)
v = grb_file->V_GRD_GDS3_ISBL(:,:,:)              ; V wind component (m/s)
rh = grb_file->R_H_GDS3_ISBL(:,:,:)               ; RH (%)
pressure_levels = grb_file->lv_ISBL2(:)           ; Pressure levels (hPa)

p = conform_dims(dimsizes(tk),pressure_levels,0)  ; Pressure

q = mixhum_ptrh(p,tk,rh,-2)                       ; Specific humidity (g/kg)

q!0="level"
q&level = pressure_levels

u!0="level"
u&level = pressure_levels 
u!1="lat2d"
u&lat2d = lat2d(:,0)
u!2="lon2d"
u&lon2d = lon2d(0,:)

v!0="level"
v&level = pressure_levels

;************************************************
; time
;************************************************

; valid time - for right title
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
  vdate_str = "Valid " + sprinti("%0.2i/", month) + sprinti("%0.2i/",day) + \
             sprinti("%0.4i", year) + " " + sprinti("%0.2i:00 ", hour)  + \
             "UTC"
  print(vdate_str)

; init time and fcst hr - for left title
  fcst_hr  = tostring(fctm)
  utc_date_init = ut_calendar(date,0)
  init_hr = floattointeger(utc_date_init(:,3))
  date_str = ""+title+" " + sprinti("%0.2i/", month) + sprinti("%0.2i/",day) + \
            sprinti("%0.4i", year) + " (" + sprinti("%0.2i:00", init_hr) + \
            ") " +fcst_hr+ " hr fcst"
  print(date_str)
;*************************************************
;compute IVT
;*************************************************

;First, compute 50-hPa layer-average wind components and layer-average q
q975 = q({1000:950},:,:)
q925 = q({950:900},:,:)
q875 = q({900:850},:,:)
q825 = q({850:800},:,:)
q775 = q({800:750},:,:)
q725 = q({750:700},:,:)
q675 = q({700:650},:,:)
q625 = q({650:600},:,:)
q575 = q({600:550},:,:)
q525 = q({550:500},:,:)
q475 = q({500:450},:,:)
q425 = q({450:400},:,:)
q375 = q({400:350},:,:)
q325 = q({350:300},:,:)
q275 = q({300:250},:,:)
q225 = q({250:200},:,:)

ql975 = dim_avg_n_Wrap(q975,0)
ql925 = dim_avg_n_Wrap(q925,0)
ql875 = dim_avg_n_Wrap(q875,0)
ql825 = dim_avg_n_Wrap(q825,0)
ql775 = dim_avg_n_Wrap(q775,0)
ql725 = dim_avg_n_Wrap(q725,0)
ql675 = dim_avg_n_Wrap(q675,0)
ql625 = dim_avg_n_Wrap(q625,0)
ql575 = dim_avg_n_Wrap(q575,0)
ql525 = dim_avg_n_Wrap(q525,0)
ql475 = dim_avg_n_Wrap(q475,0)
ql425 = dim_avg_n_Wrap(q425,0)
ql375 = dim_avg_n_Wrap(q375,0)
ql325 = dim_avg_n_Wrap(q325,0)
ql275 = dim_avg_n_Wrap(q275,0)
ql225 = dim_avg_n_Wrap(q225,0)

u975 = u({1000:950},:,:)
u925 = u({950:900},:,:)
u875 = u({900:850},:,:)
u825 = u({850:800},:,:)
u775 = u({800:750},:,:)
u725 = u({750:700},:,:)
u675 = u({700:650},:,:)
u625 = u({650:600},:,:)
u575 = u({600:550},:,:)
u525 = u({550:500},:,:)
u475 = u({500:450},:,:)
u425 = u({450:400},:,:)
u375 = u({400:350},:,:)
u325 = u({350:300},:,:)
u275 = u({300:250},:,:)
u225 = u({250:200},:,:)

ul975 = dim_avg_n_Wrap(u975,0)
ul925 = dim_avg_n_Wrap(u925,0)
ul875 = dim_avg_n_Wrap(u875,0)
ul825 = dim_avg_n_Wrap(u825,0)
ul775 = dim_avg_n_Wrap(u775,0)
ul725 = dim_avg_n_Wrap(u725,0)
ul675 = dim_avg_n_Wrap(u675,0)
ul625 = dim_avg_n_Wrap(u625,0)
ul575 = dim_avg_n_Wrap(u575,0)
ul525 = dim_avg_n_Wrap(u525,0)
ul475 = dim_avg_n_Wrap(u475,0)
ul425 = dim_avg_n_Wrap(u425,0)
ul375 = dim_avg_n_Wrap(u375,0)
ul325 = dim_avg_n_Wrap(u325,0)
ul275 = dim_avg_n_Wrap(u275,0)
ul225 = dim_avg_n_Wrap(u225,0)

v975 = v({1000:950},:,:)
v925 = v({950:900},:,:)
v875 = v({900:850},:,:)
v825 = v({850:800},:,:)
v775 = v({800:750},:,:)
v725 = v({750:700},:,:)
v675 = v({700:650},:,:)
v625 = v({650:600},:,:)
v575 = v({600:550},:,:)
v525 = v({550:500},:,:)
v475 = v({500:450},:,:)
v425 = v({450:400},:,:)
v375 = v({400:350},:,:)
v325 = v({350:300},:,:)
v275 = v({300:250},:,:)
v225 = v({250:200},:,:)

vl975 = dim_avg_n_Wrap(v975,0)
vl925 = dim_avg_n_Wrap(v925,0)
vl875 = dim_avg_n_Wrap(v875,0)
vl825 = dim_avg_n_Wrap(v825,0)
vl775 = dim_avg_n_Wrap(v775,0)
vl725 = dim_avg_n_Wrap(v725,0)
vl675 = dim_avg_n_Wrap(v675,0)
vl625 = dim_avg_n_Wrap(v625,0)
vl575 = dim_avg_n_Wrap(v575,0)
vl525 = dim_avg_n_Wrap(v525,0)
vl475 = dim_avg_n_Wrap(v475,0)
vl425 = dim_avg_n_Wrap(v425,0)
vl375 = dim_avg_n_Wrap(v375,0)
vl325 = dim_avg_n_Wrap(v325,0)
vl275 = dim_avg_n_Wrap(v275,0)
vl225 = dim_avg_n_Wrap(v225,0)

qf = (/ql975,ql925,ql875,ql825,ql775,ql725,ql675,ql625,ql575,ql525,ql475,ql425,ql375,ql325,ql275,ql225/)
qf!0 = "level"
qf&level = (/975,925,875,825,775,725,675,625,575,525,475,425,375,325,275,225/)

uf = (/ul975,ul925,ul875,ul825,ul775,ul725,ul675,ul625,ul575,ul525,ul475,ul425,ul375,ul325,ul275,ul225/)
uf!0 = "level"
uf&level = (/975,925,875,825,775,725,675,625,575,525,475,425,375,325,275,225/)

vf = (/vl975,vl925,vl875,vl825,vl775,vl725,vl675,vl625,vl575,vl525,vl475,vl425,vl375,vl325,vl275,vl225/)
vf!0 = "level"
vf&level = (/975,925,875,825,775,725,675,625,575,525,475,425,375,325,275,225/)

;Calculate u and v components of IVT

uflux = uf*(qf/9.8)*5000
vflux = vf*(qf/9.8)*5000
uIVT = dim_sum_n_Wrap(uflux,0)
vIVT= dim_sum_n_Wrap(vflux,0)
;km correct units to be kg/m/s, not g
uIVT = uIVT/1000.
vIVT= vIVT/1000.

;assign metadata
uIVT!0 = "lat2d"
uIVT&lat2d = u&lat2d
uIVT!1 = "lon2d"
uIVT&lon2d = u&lon2d
uIVT@long_name = "u-component of IVT"
uIVT@units = "kg/m/s"

vIVT!0 = "lat2d"
vIVT&lat2d = u&lat2d
vIVT!1 = "lon2d"
vIVT&lon2d = u&lon2d
vIVT@long_name = "v-component of IVT"
vIVT@units = "kg/m/s"

printVarSummary(uIVT)
printVarSummary(vIVT)

mag_IVT = (uIVT^2+vIVT^2)^0.5

printVarSummary(mag_IVT)

mag_IVT!0 = "lat2d"
mag_IVT&lat2d = uIVT&lat2d
mag_IVT!1 = "lon2d"
mag_IVT&lon2d = uIVT&lon2d
mag_IVT@long_name = "mag of IVT"
mag_IVT@units = "kg/m/s"

printVarSummary(mag_IVT)

mag_IVT@lat2d = lat2d
mag_IVT@lon2d = lon2d
uIVT@lat2d    = lat2d
uIVT@lon2d    = lon2d
vIVT@lat2d    = lat2d
vIVT@lon2d    = lon2d

;************************************************
; set corner points
;************************************************

nlat       = dimsizes(lat2d(:,0))
nlon       = dimsizes(lon2d(0,:))
xdim       = nlat - 1
ydim       = nlon - 1

x_ll       = 0
y_ll       = 0
x_ur       = nlat-1
y_ur       = nlon-1

; set the lat/lons of the corner points
lat_ll     = lat2d(x_ll,y_ll)
lon_ll     = lon2d(x_ll,y_ll)
lat_ur     = lat2d(x_ur,y_ur)
lon_ur     = lon2d(x_ur,y_ur)

;************************************************
; create plot
;************************************************
wks = gsn_open_wks("ncgm","./ua_ivt")             ; open ncgm 
gsn_define_colormap(wks,"BlueWhiteOrangeRed")              ; choose color map

res                      = True               ; plot mods desired
res@cnFillOn             = True               ; turn on color for contours
res@cnLinesOn            = True             ; turn off contour lines
res@cnLineThicknessF     = 1.0
res@cnLineLabelsOn       = False              ; turn off contour line labels
res@gsnScalarContour     = True               ; contours desired
res@gsnSpreadColors      = False             ; use full color map
res@gsnSpreadColorStart  = 144                 ; start at color 17
res@gsnSpreadColorEnd    = 250                ; end at color 200
res@mpLandFillColor       = "gray"            ; set land to be gray

; map transformation
res@mpLimitMode = "Corners"
res@mpLeftCornerLatF  = lat_ll
res@mpLeftCornerLonF  = lon_ll
res@mpRightCornerLatF = lat_ur
res@mpRightCornerLonF = lon_ur

; map projection
res@mpProjection               = "LambertConformal"
res@mpLambertParallel1F        = latin1
res@mpLambertParallel2F        = latin2
res@mpLambertMeridianF         = lov

res@lbLabelBarOn                 = True         ; Turn off individual labelbars.
res@mpFillOn                     = False        ; turn off gray fill
res@mpOutlineBoundarySets        = "AllBoundaries"   ; turn on country boundaries
res@mpProvincialLineColor        = "black"
res@mpUSStateLineColor           = "black"
res@mpGeophysicalLineColor       = "black"       ; color of cont. outlines
res@mpGeophysicalLineThicknessF  = 1.5          ; thickness of outlines
res@mpUSStateLineThicknessF      = 1.5
res@mpGeophysicalLineDashPattern = "SolidLine"
res@mpUSStateLineDashPattern  = "SolidLine"
res@cnLevelSelectionMode      = "ManualLevels"     ; set manual contour levels
res@cnMinLevelValF            = 200.               ; set min contour level
res@cnMaxLevelValF            = 1200.                 ; set max contour level
res@cnLevelSpacingF           = 100.               ; set contour spacing
res@cnFillColors              = (/28,44,52,60,84,160,168,180,196,202,212,228,244,250/)

res@vcRefMagnitudeF           = 400.0             ; define vector ref mag
res@vcRefLengthF              = 0.045           ; define length of vec ref
res@vcRefAnnoBackgroundColor  = "white"         ; color of background ref box
res@vcRefAnnoFontColor        = "black"         ; color of font in ref box
res@vcRefAnnoPerimColor       = "white"         ; color of perim around ref box
res@vcRefAnnoOrthogonalPosF   = -1.0            ; move ref vector
res@vcRefAnnoArrowLineColor   = "black"         ; change ref vector color
res@vcRefAnnoArrowUseVecColor = False           ; don't use vec color for ref
res@vcMinDistanceF            = 0.026
res@vcGlyphStyle              = "LineArrow"     ; turn on curley vectors
res@vcLineArrowColor          = "black"           ; change vector color
res@vcLineArrowThicknessF     = 3.0               ; change vector thickness
res@vcVectorDrawOrder         = "PostDraw"        ; draw vectors last
res@gsnMaximize               = True
res@vcLineArrowHeadMaxSizeF   = 0.005
res@vcLineArrowHeadMinSizeF   = .005
res@lbOrientation             = "Horizontal"     ; vertical label bar
res@pmLabelBarOrthogonalPosF  = 0.0          ; move label bar closer
res@lbLabelStride             = 1
res@pmLabelBarWidthF          = 0.55               ; default is shorter
res@pmLabelBarHeightF         = 0.08               ; default is taller
res@lbLabelFont               = "helvetica"
res@lbLabelFontHeightF        = .015
res@lbTitleFontHeightF        = .015
res@lbTitlePosition           = "bottom"
res@lbTitleString             = "(kg m~S~-1~N~ s~S~-1~N~)"
res@gsnDraw                   = False                   ; do not draw the plot
res@gsnFrame                  = False
res@gsnAddCyclic              = False
res@vcMonoFillArrowFillColor  = True
res@vcFillArrowFillColor      = 1
res@gsnPaperOrientation       = "landscape"

; viewport
point1 = stringtoint(point1_str)
point2 = stringtoint(point2_str)
nxin   = stringtoint(nxin_str)
nyin   = stringtoint(nyin_str)

nx = nxin 
ny = nyin 
xdim = nx - 1
ydim = ny - 1
rnx = 1.*xdim
rny = 1.*ydim
if (domain .eq. "d01")
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
else
  if (rny .ge. rnx) then
    vpheight = .96
    vpy = 1.-((1.-vpheight)/2.)
    vpwidth = (vpheight/rny)*rnx
    vpx = (1.-((vpheight/rny)*rnx))/2.
  else
    vpwidth = .75
    vpx = (1.-vpwidth)/2.
    vpheight = (vpwidth/rnx)*rny
    vpy = 1.-((1.-((vpwidth/rnx)*rny))/2.)
  end if
end if

res@vpXF          = vpx
res@vpYF          = vpy       
res@vpWidthF      = vpwidth
res@vpHeightF     = vpheight

; titles
res@gsnCenterString                 = "Integrated Vapor Transport (kg m~S~-1~N~s ~S~-1~N~)"
res@gsnCenterStringFontColor        = 181
res@gsnCenterStringFontHeightF      = 0.02
res@gsnCenterStringOrthogonalPosF   = 0.005
res@gsnRightString                 = ""+vdate_str+""
res@gsnRightStringFontColor        = "foreground"
res@gsnRightStringFontHeightF      = 0.015
res@gsnRightStringOrthogonalPosF   = 0.057
res@gsnLeftString                  = ""+date_str+""
res@gsnLeftStringFontColor         = "foreground"
res@gsnLeftStringFontHeightF       = 0.015
res@gsnLeftStringOrthogonalPosF    = 0.055
res@txFont                         = 22

plot1 = gsn_csm_vector_scalar_map(wks,uIVT(:,:),vIVT(:,:),mag_IVT(:,:),res)

draw(plot1)
frame(wks)

end

