Esca Syntax

defun add($a, $b)
    return($a + $b)
end


unless 222 == 111 then
    print 222
end

if 33 > 22 then
    print "hello"
else
    print "byebye"
end


defun hello($name)
    print("hello " ++ $name)
end

foreach $var in [333, 222, 99] do
    print $var
end

hello "hans"
