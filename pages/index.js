import { PhotoIcon, UserCircleIcon } from '@heroicons/react/24/solid'
import { useState } from 'react';

export default function Home() {
  const [file, setFile] = useState(null);
  const [text, setText] = useState('');

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    const formData = new FormData();
    formData.append('file', file);

    const res = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    });

    const { text } = await res.json();
    setText(text);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div class="flex items-center justify-center h-screen bg-gray-200">
        <div class="w-full max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden md:max-w-2xl">
            <div class="md:flex">
                <div class="md:flex-shrink-0">
                    <img class="h-48 w-full object-cover md:h-full md:w-48" src="https://raw.githubusercontent.com/smmalik3/get-text-from-image/main/public/GTFI_Logo_Small.png" alt="Upload Placeholder"></img>
                </div>
                <div class="p-8">
                    <div class="uppercase tracking-wide text-sm text-indigo-500 font-semibold">Get Text From Image</div>
                    <input type="file" class="w-full py-2 px-3 text-grey-darker mt-2 mb-3 leading-tight focus:outline-none focus:shadow-outline"></input>
                    <button class="mt-3 px-5 py-2 text-sm text-white transition-colors duration-150 bg-purple-600 rounded-lg focus:shadow-outline hover:bg-purple-700">Upload</button>
                    <button class="mt-3 ml-3 px-5 py-2 text-sm text-white transition-colors duration-150 bg-blue-600 rounded-lg focus:shadow-outline hover:bg-blue-700">Submit</button>
                </div>
            </div>
        </div>
      </div>
    </form>
  )
}