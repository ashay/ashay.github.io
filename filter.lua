function Link(el)
  el.target = string.gsub(el.target, "%.txt", ".html")
  return el
end
