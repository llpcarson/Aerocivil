;************************************************
; load required libraries, envars, and begin
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;title = getenv ("TITLE") + " "
;point1_str = getenv ("POINT1")
;point2_str = getenv ("POINT2")
;nxin_str = getenv ("NXIN")
;nyin_str = getenv ("NYIN")
;stride = getenv ("STRIDE")

function gen_colormap( )
begin
        ; Set rgb colors

        ; The continental outlines in the map object use this color
        ; as a default.

        return( (/ \
         (/1.00,1.00,1.00/), \  ; white      0
         (/0.00,0.00,0.00/), \  ; black      1
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

begin

;************************************************
; read in grib data (config1 and config2)
;************************************************  
  
fname = asciiread("arw1_file.txt",-1,"string")
grb_file   = addfile(fname,"r")
;grb_file   = addfile("WRFNAT_d02_42.tm00.grb","r")
;grb_file   = addfile("wrfprs_d02_42.tm00.grb","r")
names      = getfilevarnames(grb_file)

ref_name="REFD_GDS3_ISBL"
intm = grb_file->$ref_name$@initial_time
fctm = grb_file->$ref_name$@forecast_time
lat2d = grb_file->g3_lat_0(:,:)
lon2d = grb_file->g3_lon_1(:,:)
latin1 = grb_file->g3_lat_0@Latin1
latin2 = grb_file->g3_lat_0@Latin2
lov = grb_file->g3_lon_1@Lov

grb_ref        = grb_file->$ref_name$(:,:,:)
grb_ref@lat2d  = lat2d
grb_ref@lon2d  = lon2d

nlat       = dimsizes(lat2d(:,0))
nlon       = dimsizes(lon2d(0,:))

xdim       = nlat - 1
ydim       = nlon - 1

max_ref = dim_max_n(grb_ref,0)
max_ref@lat2d = lat2d
max_ref@lon2d = lon2d

printVarSummary(lat2d)

;************************************************
; time
;************************************************

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

;************************************************
; set corner points
;************************************************
x_ll                  = 0
y_ll                  = 0
x_ur                  = nlat-1
y_ur                  = nlon-1

; set the lat/lons of the corner points
lat_ll                = lat2d(x_ll,y_ll)
lon_ll                = lon2d(x_ll,y_ll)
lat_ur                = lat2d(x_ur,y_ur)
lon_ur                = lon2d(x_ur,y_ur)


;************************************************
; create plot
;************************************************
wks = gsn_open_wks("png","max_ref_poly_wrfprs")
;wks = gsn_open_wks("ncgm","./max_ref_poly")

gsn_define_colormap(wks,gen_colormap())

res                            = True

res@gsnFrame                   = False
res@gsnMaximize                = True
res@gsnPaperOrientation        = "landscape"

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

;res@tfDoNDCOverlay = True

; map resources
res@mpPerimOn                  = True
res@mpPerimLineThicknessF      = 4.0
res@gsnDraw                    = False
res@mpDataBaseVersion = "Ncarg4_1"
res@mpDataSetName = "Earth..4"
res@mpOutlineDrawOrder         = "PostDraw"
res@mpOutlineBoundarySets      = "GeophysicalAndUSStates"
res@mpUSStateLineColor         =  "black"
res@mpUSStateLineThicknessF    = 2.0
res@mpNationalLineColor        = "black"
res@mpGeophysicalLineColor     = "black"
res@mpGeophysicalLineThicknessF = 2.0 
;res@mpFillOn                   = False
res@mpFillOn                   = True
res@mpGridAndLimbOn            = False
;res@pmTickMarkDisplayMode      = "Always"
;res@mpInlandWaterFillColor = 2
;res@mpOceanFillColor = 2
res@cnMissingValFillColor = "White"

res@cnFillOn            = True         ; turn on contour fill
res@cnFillMode          = "RasterFill"
res@gsnSpreadColors     = True         ; use full colormap   

res@cnLinesOn          = False        ; turn off contour lines
res@cnLineLabelsOn     = False        ; turn off line labels
res@cnInfoLabelOn      = False        ; turn off info label
res@lbBoxLinesOn       = False        ; turn off labelbar box lines

res@lbLabelAutoStride          = True              ; nice lb labels
res@cnLevelSelectionMode       = "ExplicitLevels"    ; set manual contour levels
res@cnFillColors = (/0,0,4,3,2,20,6,7,8,21,9,11,19,18,15,14,1/)
res@cnLevels = (/ 0.,5.,10.,15.,20.,25.,30.,35.,40.,45.,50.,55.,60.,65.,70.,75./)
res@lbTitlePosition            = "Bottom"
res@pmTickMarkDisplayMode      = "NoCreate"
res@pmLabelBarDisplayMode      = "ALWAYS"
res@pmLabelBarHeightF          = .05
res@pmLabelBarWidthF           = 0.9
res@pmLabelBarSide             = "bottom"
res@pmLabelBarOrthogonalPosF   = 0.0
;res@lbTitleFontHeightF         = .01          ; make title smaller
res@lbBoxLinesOn               = True

lat_pt=275
lon_pt1=240
lon_pt2=340

y1=(lat2d(lat_pt,lon_pt1))
y2=(lat2d(lat_pt,lon_pt2))
x1=(lon2d(lat_pt,lon_pt1))
x2=(lon2d(lat_pt,lon_pt2))

print(y1)
print(y2)
print(x1)
print(x2)

; viewport
point1 = 499
point2 = 724 
nxin   = 725
nyin   = 500

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

res@vpXF          = vpx
res@vpYF          = vpy       
res@vpWidthF      = vpwidth
res@vpHeightF     = vpheight

; titles
res@gsnCenterString                 = "Maximum Simulated Radar Reflectivity (dbZ)"
res@gsnCenterStringFontColor        = "black"
res@gsnCenterStringFontHeightF      = 0.02
res@gsnCenterStringOrthogonalPosF   = 0.005
res@gsnRightString                 = ""+date_str+""
res@gsnRightStringFontColor        = "black"
res@gsnRightStringFontHeightF      = 0.015
res@gsnRightStringOrthogonalPosF   = 0.057
res@gsnLeftString                  = "RAPps "+intm+" "+fctm+" hr fcst"
res@gsnLeftStringFontColor         = "black"
res@gsnLeftStringFontHeightF       = 0.015
res@gsnLeftStringOrthogonalPosF    = 0.055
res@txFont                         = 22

map = gsn_csm_contour_map(wks,max_ref,res)
draw(map)

pres=True
pres@gsLineColor      = "red"          ; color of lines
pres@gsLineThicknessF = 3.0            ; line thickness   

gsn_polyline(wks,map,(/x1,x2/),(/y1,y2/),pres)
frame(wks)

end
