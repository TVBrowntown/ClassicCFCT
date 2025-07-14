[![](http://img.youtube.com/vi/gNMEFNtfaEQ/0.jpg)](http://www.youtube.com/watch?v=gNMEFNtfaEQ "Youtube link")

# ClassicCFCT
Highly customizable "Floating Combat Text" addon with text anti-overlap behavior similiar to that of WoW Classic.
 
Use "/cfct" command to open the options interface.
 
Currently there are 2 configuration presets built-in: "Classic" and "Mists of Pandaria".
Users can create their own presets.

Text display area can be positioned in 3 ways: 
- to screen center (with x, y offsets)
- to the target nameplate
- to every individual nameplate (anti-overlap doesnt work in this mode courtesy of Blizzard)

If no nameplate is available (in case the target dies or moves off-screen), text display area can fall back to screen center.
Text can be displayed behind or in front of nameplates and their children.

Animations:
- Fade In, Fade Out
- Directional Scroll
- Pow (a 2 stage scale animation for crits)

Configurable variables include:
- animation timing, scale and duration.
- text font, style, size, custom color or by damage type.
- anti-overlap spacing
- spell icons for each damage/heal event.
- filtering, sorting, merging

Use the below commands to switch between the two presets

/run ClassicCFCT.Config:LoadPreset("Mists of Pandaria")
/run ClassicCFCT.Config:LoadPreset("Classic")
