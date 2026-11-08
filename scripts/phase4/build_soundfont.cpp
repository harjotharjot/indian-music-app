// Asset container writer using SF2cute. No synthesis or playback DSP.
#include <sf2cute.hpp>
#include <fstream>
#include <iterator>
#include <vector>
#include <memory>
#include <algorithm>
#include <iostream>
using namespace sf2cute;
struct Row { int key; std::string path; unsigned start,end; };
int main(int argc,char**argv) {
 if(argc!=3)return 2;
 std::ifstream list(argv[1]);std::vector<Row> rows;Row r;
 while(list>>r.key>>r.path>>r.start>>r.end)rows.push_back(r);
 std::sort(rows.begin(),rows.end(),[](const Row&a,const Row&b){return a.key<b.key;});
 SoundFont sf;sf.set_bank_name("Recorded Harmonium");sf.set_sound_engine("EMU8000");
 auto instrument=sf.NewInstrument("Harmonium");
 for(size_t i=0;i<rows.size();++i){
  auto &x=rows[i];std::ifstream f(x.path,std::ios::binary);
  std::vector<char> bytes((std::istreambuf_iterator<char>(f)),{});std::vector<int16_t> data;
  for(size_t j=0;j+1<bytes.size();j+=2)data.push_back(int16_t(uint16_t(uint8_t(bytes[j]))|(uint16_t(uint8_t(bytes[j+1]))<<8)));
  auto sample=sf.NewSample("Reed"+std::to_string(x.key),data,x.start,x.end,48000,uint8_t(x.key),0);
  int low=i==0?0:(rows[i-1].key+x.key)/2+1;
  int high=i+1==rows.size()?127:(x.key+rows[i+1].key)/2;
  SFInstrumentZone zone(sample,std::vector<SFGeneratorItem>{
   SFGeneratorItem(SFGenerator::kKeyRange,RangesType(uint8_t(low),uint8_t(high))),
   SFGeneratorItem(SFGenerator::kSampleModes,uint16_t(SampleMode::kLoopContinuously)),
   SFGeneratorItem(SFGenerator::kAttackVolEnv,int16_t(-10800)),
   SFGeneratorItem(SFGenerator::kReleaseVolEnv,int16_t(-4373)),
  },std::vector<SFModulatorItem>{});
  instrument->AddZone(std::move(zone));
 }
 sf.NewPreset("Harmonium",0,0,std::vector<SFPresetZone>{SFPresetZone(instrument)});
 std::ofstream out(argv[2],std::ios::binary);sf.Write(out);
 std::cout<<"Wrote "<<rows.size()<<" recorded zones\n";
}
