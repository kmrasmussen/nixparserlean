import Lake
open Lake DSL

package «nixparserlean» where

lean_lib NixParserLean where

@[default_target]
lean_exe nixparserlean where
  root := `Main
