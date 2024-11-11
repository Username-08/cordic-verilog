with open("unwrap.txt", "r+") as f:
    txt = f.read()
    for i in range(15):
        n_txt = txt.replace("$", str(i))
        print(n_txt)
        f.write(n_txt)
