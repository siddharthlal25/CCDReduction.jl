using CCDReduction: getdata

function test_header(ccd1::CCDData, ccd2::CCDData)
    header1 = ccd1.hdr
    header2 = ccd2.hdr
    @test keys(header1) == keys(header2)
    for (k1, k2) in zip(keys(header1), keys(header2))
        @test header1[k1] == header2[k2]
    end
end

@testset "bias subtraction(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    hdu_bias_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])
    array_bias_frame = getdata(M6707HH[1])

    # non-mutating version
    # testing CCDData CCDData case
    processed_frame = subtract_bias(hdu_frame, hdu_bias_frame)
    @test processed_frame isa CCDData
    @test processed_frame.data == zeros(1059, 1059)
    test_header(processed_frame, hdu_frame)

    ## testing Array CCDData case
    processed_frame = subtract_bias(array_frame, hdu_bias_frame)
    @test processed_frame isa Array
    @test processed_frame == zeros(1059, 1059)

    # testing CCDData case
    processed_frame = subtract_bias(hdu_frame, array_bias_frame)
    @test processed_frame isa CCDData
    @test processed_frame.data == zeros(1059, 1059)
    test_header(processed_frame, hdu_frame)

    # testing mutating version
    # testing CCDData CCDData case
    hdu_frame = CCDData(M6707HH[1])
    subtract_bias!(hdu_frame, hdu_bias_frame)
    @test hdu_frame isa CCDData
    @test hdu_frame.data == zeros(1059, 1059)

    # testing CCDData Array case
    hdu_frame = CCDData(M6707HH[1])
    subtract_bias!(hdu_frame, array_bias_frame)
    @test hdu_frame isa CCDData
    @test hdu_frame.data == zeros(1059, 1059)

    # testing Array CCDData case
    array_frame = getdata(M6707HH[1])
    subtract_bias!(array_frame, hdu_bias_frame)
    @test array_frame isa Array
    @test array_frame == zeros(1059, 1059)

    # testing error in mutating version
    hdu_frame = CCDData(fill(2, 5, 5), read_header(M6707HH[1]))
    hdu_bias = CCDData(fill(2.5, 5, 5), read_header(M6707HH[1]))
    @test_throws InexactError subtract_bias!(hdu_frame, hdu_bias)
end

@testset "overscan subtraction(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])

    # testing non-mutating version
    processed_frame = subtract_overscan(hdu_frame, (:, 1050:1059))
    @test processed_frame isa CCDData
    @test processed_frame.data == subtract_overscan(array_frame, (:, 1050:1059))
    test_header(processed_frame, hdu_frame)

    processed_frame = subtract_overscan(hdu_frame, "1050:1059, 1:1059")
    processed_frame isa CCDData
    @test processed_frame.data == subtract_overscan(array_frame, (:, 1050:1059))

    # testing mutating version
    hdu_frame = CCDData(M6707HH[1])
    subtract_overscan!(hdu_frame, (:, 1050:1059))
    @test hdu_frame.data == subtract_overscan(array_frame, (:, 1050:1059))

    hdu_frame = CCDData(M6707HH[1])
    subtract_overscan!(hdu_frame, "1050:1059, 1:1059")
    @test hdu_frame.data == subtract_overscan(array_frame, (:, 1050:1059))
end

@testset "flat correction(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    hdu_flat_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])
    array_flat_frame = getdata(M6707HH[1])
    mean_flat_frame = mean(array_flat_frame)

    # testing non mutating version
    # testing CCDData CCDData case
    processed_image = flat_correct(hdu_frame, hdu_flat_frame)
    @test processed_image isa CCDData
    test_header(processed_image, hdu_frame)
    @test processed_image.data ≈ fill(mean_flat_frame, 1059, 1059)

    # testing CCDData Array case
    processed_image = flat_correct(hdu_frame, array_flat_frame; norm_value = 1)
    @test processed_image isa CCDData
    @test processed_image.data ≈ ones(1059, 1059)

    # testing Array CCDData case
    processed_image = flat_correct(array_frame, hdu_flat_frame; norm_value = 1)
    @test processed_image isa Array
    @test processed_image ≈ ones(1059, 1059)

    # testing type mutation in non mutating version
    hdu_frame = CCDData(fill(1, 5, 5), read_header(M6707HH[1]))
    bias_frame = CCDData(fill(2.0, 5, 5), read_header(M6707HH[1]))
    processed_image = flat_correct(hdu_frame, bias_frame; norm_value = 1)
    @test processed_image isa CCDData
    @test processed_image.data ≈ fill(0.5, 5, 5)

    # testing mutating version
    hdu_frame = CCDData(ones(5, 5), read_header(M6707HH[1]))
    flat_correct!(hdu_frame, fill(2.0, 5, 5); norm_value = 1)
    @test hdu_frame.data ≈ fill(0.5, 5, 5)

    # testing type error in mutating version
    frame = CCDData(fill(1, 5 ,5), read_header(M6707HH[1]))
    @test_throws InexactError flat_correct!(frame, fill(2.0, 5, 5); norm_value = 1)
end

@testset "trim(FITS)" begin
    # setting initial data
    hdu = M6707HH[1]
    data = read(hdu)'

    # testing non-mutating version
    @test trim(data, (:, 1050:1059)) == trim(test_file_path_M6707HH, (:, 1050:1059))
    @test trim(data, (:, 1050:1059)) == trim(test_file_path_M6707HH, "1050:1059, 1:1059")
    @test trim(data, (:, 1050:1059)) == trim(hdu, "1050:1059, 1:1059")
    @test trim(data, (1050:1059, :)) == trim(hdu, "1:1059, 1050:1059")
end

@testset "cropping(FITS)" begin
    # setting initial data
    hdu = M6707HH[1]
    data = read(hdu)'

    # testing non-mutating version
    @test crop(data, (:, 5)) == crop(hdu, (:, 5))
    @test crop(data, (1000, 5); force_equal = false) == crop(hdu, (1000, 5); force_equal = false)
    @test_logs (:warn, "dimension 1 changed from 348 to 349") (:warn, "dimension 2 changed from 226 to 227") (:warn, "dimension 1 changed from 348 to 349") (:warn, "dimension 2 changed from 226 to 227") @test crop(data, (348, 226)) == crop(test_file_path_M6707HH, (348, 226))
    @test crop(data, (348, 226); force_equal = false) == crop(test_file_path_M6707HH, (348, 226); force_equal = false)
end


@testset "combine(FITS)" begin
    # setting initial data
    frame = M6707HH[1] |> getdata
    vector_hdu = [M6707HH[1] for i in 1:3]
    vector_frames = [frame for i in 1:3]
    vector_frames_dir = [test_file_path_M6707HH for i in 1:3]

    # testing the vector version
    @test combine(vector_hdu) == combine(vector_frames)
    @test combine(vector_frames_dir) == combine(vector_frames)

    # testing the varargs version
    @test combine(M6707HH[1], M6707HH[1], M6707HH[1]) == combine(vector_frames)
    @test combine(test_file_path_M6707HH, test_file_path_M6707HH, test_file_path_M6707HH) == combine(vector_frames)

    # testing with kwargs
    @test combine(vector_frames_dir; hdu = 1, method = sum) == combine(vector_frames_dir; hdu = (1, 1, 1), method = sum)
    @test combine(test_file_path_M6707HH, test_file_path_M6707HH; hdu = 1) == combine(test_file_path_M6707HH, test_file_path_M6707HH)
end


@testset "dark subtraction(FITS)" begin
    # setting initial data
    hdu_frame = M6707HH[1]
    hdu_bias_frame = M6707HH[1]
    array_frame = read(hdu_frame)'
    array_bias_frame = read(hdu_bias_frame)'
    string_bias_frame = test_file_path_M6707HH
    string_frame = test_file_path_M6707HH

    # testing non-mutating version
    @test subtract_dark(array_frame, array_bias_frame; dark_exposure = 0.5) == (-1).* array_frame # testing Array Array case
    @test subtract_dark(array_frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing Array ImageHDU case
    @test subtract_dark(hdu_frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing ImageHDU ImageHDU case
    @test subtract_dark(hdu_frame, array_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing ImageHDU Array case
    @test subtract_dark(array_frame, string_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing Array String case
    @test subtract_dark(string_frame, array_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing String Array case
    @test subtract_dark(string_frame, string_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testsing String String case
    @test subtract_dark(string_frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing String ImageHDU case
    @test subtract_dark(hdu_frame, string_bias_frame; data_exposure = 2, dark_exposure = 2) == zeros(1059, 1059) # testing ImageHDU String case

    # testing with Symbols
    @test subtract_dark(hdu_frame, hdu_bias_frame; data_exposure = :EXPOSURE, dark_exposure = :EXPOSURE) == zeros(1059, 1059)
    @test subtract_dark(string_frame, string_bias_frame; data_exposure = :EXPOSURE, dark_exposure = :EXPOSURE) == zeros(1059, 1059)
    @test subtract_dark(array_frame, hdu_bias_frame; dark_exposure = :EXPOSURE) ≈ (49 / 50) .* array_frame

    #testing mutating version
    frame = read(hdu_frame)'
    subtract_dark!(frame, string_bias_frame; hdu = 1, data_exposure = 1, dark_exposure = 1)
    @test frame == zeros(1059, 1059) # testing Array String Case

    frame = read(hdu_frame)'
    subtract_dark!(frame, hdu_bias_frame; data_exposure = 2, dark_exposure = 2)
    @test frame == zeros(1059, 1059)
end

@testset "helper(FITS)" begin
    # testing getdata
    hdu = M6707HH[1]
    data = read(hdu)'
    @test data == getdata(hdu)
end
