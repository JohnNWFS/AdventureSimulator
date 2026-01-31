for /r %f in (*.gml) do (
  echo.>>all_scripts_combined.gml
  echo ===== FILE: %f =====>>all_scripts_combined.gml
  type "%f">>all_scripts_combined.gml
)
pause