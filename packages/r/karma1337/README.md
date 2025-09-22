# Conway's Game of LiA Conway's Game of Life implementation built for Gno.

## Files

```
packages/r/karma1337/conway/
├── README.md          # Documentation
├── conway.gno         # Main API and coordinates
├── grid.gno           # Game logic
├── patterns.gno       # Blinker, block, glider patterns
├── renderer.gno       # Web display
└── game.gno           # Game state
```

## Package Path

When deployed, this will be available at: `gno.land/r/karma1337/conway`

## What's included

- Works with both numeric (5,5) and letter coordinates (F5)
- Classic patterns: blinker, block, glider
- Nice web interface
- Help documentation built-in
- Optimized for Gno blockchain

## How to use

1. **New game:**
   ```bash
   gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "NewGame" --broadcast [key]
   ```

2. **Add a glider pattern:**
   ```bash
   gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "LoadPatternAt" -args "glider" -args "C3" --broadcast [key]
   ```

3. **Check it out:**
   Go to `https://gno.land/r/karma1337/conway`

## Notes

- Built for Gno standards
- Uses only Gno standard library  
- Tested locally with gnodev
- Check out the full docs in `conway/README.md` for more details