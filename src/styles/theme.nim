import strformat

type Theme* = object
  primary*, primaryLight*, primaryDark*: string
  secondary*, secondaryLight*, secondaryDark*: string
  background*, text*: string

const primary* = "primary"
const primaryLight* = "primary-light"
const primaryDark* = "primary-dark"
const secondary* = "secondary"
const secondaryLight* = "secondary-light"
const secondaryDark* = "secondary-dark"

proc buildThemeSheet*(theme: Theme): string =
  if theme.primary != "":
    result = result & fmt"""* [color="{primary}"] {{ background-color: {theme.primary};}} """
    result = result & fmt"""* [colorhover="{primary}"]:hover {{ background-color: {theme.primary};}} """
  if theme.primaryLight != "":
    result = result & fmt"""* [color="{primaryLight}"] {{ background-color: {theme.primaryLight};}} """
    result = result & fmt"""* [colorhover="{primaryLight}"]:hover {{ background-color: {theme.primaryLight};}} """
  if theme.primaryDark != "":
    result = result & fmt"""* [color="{primaryDark}"] {{ background-color: {theme.primaryDark};}} """
    result = result & fmt"""* [colorhover="{primaryDark}"]:hover {{ background-color: {theme.primaryDark};}} """
  if theme.secondary != "":
    result = result & fmt"""* [color="{secondary}"] {{ background-color: {theme.secondary};}} """
    result = result & fmt"""* [colorhover="{secondary}"]:hover {{ background-color: {theme.secondary};}} """
  if theme.secondaryLight != "":
    result = result & fmt"""* [color="{secondaryLight}"] {{ background-color: {theme.secondaryLight};}} """
    result = result & fmt"""* [colorhover="{secondaryLight}"]:hover {{ background-color: {theme.secondaryLight};}} """
  if theme.secondaryDark != "":
    result = result & fmt"""* [color="{secondaryDark}"] {{ background-color: {theme.secondaryDark};}} """
    result = result & fmt"""* [colorhover="{secondaryDark}"]:hover {{ background-color: {theme.secondaryDark};}} """
  if theme.background != "":
    result = result & fmt"body {{ background-color: {theme.background};}} "
  if theme.text != "":
    result = result & fmt"body {{ color: {theme.text};}} "
