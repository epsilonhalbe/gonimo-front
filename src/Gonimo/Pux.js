exports.differentObject = function(obj1) {
    return function(obj2) {
        return (obj1 !== obj2);
    }
}
