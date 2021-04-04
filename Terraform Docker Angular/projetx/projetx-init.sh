RED='\033[0;31m'
NC='\033[0m' # No Color

echo "${RED}[Update APT]${NC}"
sudo apt-get update -y > /dev/null

echo "${RED}[Set max watches]${NC}"
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

echo "${RED}[SSH Key : change right access to 400]${NC}"
sudo chmod 400 .ssh/GithubPrivateKey > /dev/null
sudo chmod 400 .ssh/VsCodePublicKey > /dev/null

echo "${RED}[SSH Key : authorize Vscode key]${NC}"
cat .ssh/VsCodePublicKey >> .ssh/authorized_keys

echo "${RED}[Install Chromium dependencies]${NC}"
sudo apt-get install -y ca-certificates fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 lsb-release wget xdg-utils > /dev/null

echo "${RED}[Install nodejs and npm]${NC}"
sudo apt-get install nodejs npm -y > /dev/null

echo "${RED}[Upgrade nodejs to latest stable]${NC}"
sudo npm install -g n > /dev/null
sudo n stable > /dev/null

echo "${RED}[Install Angular CLI]${NC}"
sudo npm install -g @angular/cli > /dev/null

echo "${RED}[Clone dev repository]${NC}"
git config --global user.name "Your user name"
git config --global user.email "your email"
git clone [your repo]


echo "${RED}[Set owner on ~/.config]${NC}"
sudo chown -R $USER:$(id -gn $USER) ~/.config

echo "${RED}[Setup dev environment]${NC}"
cd ~/projetx
git checkout dev
npm install > /dev/null

echo "${RED}[Done]${NC}"
